<?php
/**
 * Matrix Redis Object Cache drop-in.
 *
 * Places into wp-content/object-cache.php. Connects to the shared Redis
 * container (hostname "redis", port 6379). Falls back to in-memory array
 * caching when phpredis is unavailable or the connection fails.
 *
 * This is a minimal, dependency-free replacement for plugin-managed drop-ins.
 */

if (!defined('ABSPATH')) {
    exit;
}

class WP_Object_Cache {

    private $redis        = null;
    private $has_redis    = false;
    private $prefix       = '';
    private $cache        = array();
    private $global_group = array();
    private $no_redis_group = array();

    public function __construct() {
        $this->prefix = defined('WP_CACHE_KEY_SALT') ? WP_CACHE_KEY_SALT : 'matrix';

        if (class_exists('Redis')) {
            try {
                $this->redis = new Redis();
                $connected = $this->redis->connect('redis', 6379, 1);
                if ($connected) {
                    $redis_password = defined('REDIS_PASSWORD') ? REDIS_PASSWORD : (getenv('REDIS_PASSWORD') ?: '');
                    if (!empty($redis_password)) {
                        $this->redis->auth($redis_password);
                    }
                    $this->redis->setOption(Redis::OPT_SERIALIZER, Redis::SERIALIZER_PHP);
                    $this->redis->setOption(Redis::OPT_PREFIX, $this->prefix . ':');
                    $this->has_redis = true;
                }
            } catch (Exception $e) {
                $this->redis = null;
            }
        }
    }

    public function add($key, $data, $group = 'default', $expire = 0) {
        if (wp_suspend_cache_addition()) {
            return false;
        }
        if (isset($this->cache[$group][$key])) {
            return false;
        }
        return $this->set($key, $data, $group, $expire);
    }

    public function set($key, $data, $group = 'default', $expire = 0) {
        $this->cache[$group][$key] = $data;

        if ($this->has_redis && !isset($this->no_redis_group[$group])) {
            try {
                $redis_key = $this->redis_key($key, $group);
                if ($expire > 0) {
                    $this->redis->setex($redis_key, $expire, $data);
                } else {
                    $this->redis->set($redis_key, $data);
                }
            } catch (Exception $e) {
                // Redis hiccup — local cache is enough
            }
        }
        return true;
    }

    public function get($key, $group = 'default', $force = false, &$found = null) {
        if (!$force && isset($this->cache[$group][$key])) {
            $found = true;
            return $this->cache[$group][$key];
        }

        if ($this->has_redis && !isset($this->no_redis_group[$group])) {
            try {
                $redis_key = $this->redis_key($key, $group);
                $value = $this->redis->get($redis_key);
                if ($value !== false) {
                    $this->cache[$group][$key] = $value;
                    $found = true;
                    return $value;
                }
            } catch (Exception $e) {
                // fall through
            }
        }

        $found = false;
        return false;
    }

    public function delete($key, $group = 'default') {
        unset($this->cache[$group][$key]);

        if ($this->has_redis && !isset($this->no_redis_group[$group])) {
            try {
                $this->redis->del($this->redis_key($key, $group));
            } catch (Exception $e) {
                // ignore
            }
        }
        return true;
    }

    public function replace($key, $data, $group = 'default', $expire = 0) {
        if (!isset($this->cache[$group][$key])) {
            return false;
        }
        return $this->set($key, $data, $group, $expire);
    }

    public function flush($group = null) {
        if ($group === null) {
            $this->cache = array();
            if ($this->has_redis) {
                try {
                    $this->redis->flushAll();
                } catch (Exception $e) {
                    // ignore
                }
            }
        } else {
            unset($this->cache[$group]);
        }
        return true;
    }

    public function add_global_groups($groups) {
        $groups = (array) $groups;
        foreach ($groups as $group) {
            $this->global_group[$group] = true;
        }
    }

    public function add_non_persistent_groups($groups) {
        $groups = (array) $groups;
        foreach ($groups as $group) {
            $this->no_redis_group[$group] = true;
        }
    }

    public function stats() {
        // not implemented
    }

    public function close() {
        if ($this->has_redis) {
            try {
                $this->redis->close();
            } catch (Exception $e) {
                // ignore
            }
        }
        return true;
    }

    private function redis_key($key, $group) {
        if (isset($this->global_group[$group])) {
            return $group . ':' . $key;
        }
        return $this->prefix . ':' . $group . ':' . $key;
    }
}

function wp_cache_init() {
    $GLOBALS['wp_object_cache'] = new WP_Object_Cache();
}

function wp_cache_add($key, $data, $group = '', $expire = 0) {
    return $GLOBALS['wp_object_cache']->add($key, $data, $group, $expire);
}

function wp_cache_set($key, $data, $group = '', $expire = 0) {
    return $GLOBALS['wp_object_cache']->set($key, $data, $group, $expire);
}

function wp_cache_get($key, $group = '', $force = false, &$found = null) {
    return $GLOBALS['wp_object_cache']->get($key, $group, $force, $found);
}

function wp_cache_delete($key, $group = '') {
    return $GLOBALS['wp_object_cache']->delete($key, $group);
}

function wp_cache_replace($key, $data, $group = '', $expire = 0) {
    return $GLOBALS['wp_object_cache']->replace($key, $data, $group, $expire);
}

function wp_cache_flush($group = null) {
    return $GLOBALS['wp_object_cache']->flush($group);
}

function wp_cache_add_global_groups($groups) {
    $GLOBALS['wp_object_cache']->add_global_groups($groups);
}

function wp_cache_add_non_persistent_groups($groups) {
    $GLOBALS['wp_object_cache']->add_non_persistent_groups($groups);
}

function wp_cache_reset() {
    $GLOBALS['wp_object_cache']->flush(null);
}

function wp_cache_close() {
    return $GLOBALS['wp_object_cache']->close();
}

function wp_cache_supports($feature) {
    return false;
}
