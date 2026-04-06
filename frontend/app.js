app.get('/api/health/:siteName', async (req, res) => {
  const { siteName } = req.params;
  
  if (!siteName || !/^[a-zA-Z0-9_-]+$/.test(siteName)) {
    return sendError(res, 'INVALID_NAME', 'Invalid site name', 400);
  }
  
  try {
    const port = await getSitePort(siteName);
    if (!port) {
      return res.json({ success: true, site: siteName, healthy: false, reason: 'Site not running or no port' });
    }
    
    const url = `http://localhost:${port}`;
    const startTime = Date.now();
    
    try {
      const response = await fetch(url, { 
        method: 'HEAD',
        signal: AbortSignal.timeout(5000)
      });
      const responseTime = Date.now() - startTime;
      
      res.json({
        success: true,
        site: siteName,
        healthy: response.ok,
        status: response.status,
        responseTime: `${responseTime}ms`,
        url
      });
    } catch (fetchError) {
      res.json({
        success: true,
        site: siteName,
        healthy: false,
        error: fetchError.message,
        url
      });
    }
  } catch (error) {
    sendError(res, 'COMMAND_FAILED', error.message);
  }
});

const getSitePort = async (siteName) => {
  const result = await executeMatrix('list', [], true);
  const site = result.data?.sites?.find(s => s.name === siteName);
  return site?.port || null;
};