<?php
/**
 * Fin V2 — content helper.
 *
 * Comparison pages have no ACF body fields — copy lives in template-parts/fin-v2/.
 * Only the Marketo form ID is dynamic (constant 7377 across the comparison family).
 *
 * All Fin-specific copy is now authored. No remaining Forethought placeholders.
 *
 * @package SearchUnify
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * TL;DR section heading.
 *
 * @return string
 */
function su_finv2_tldr_heading() {
	return 'TL;DR';
}

/**
 * TL;DR body paragraphs (display order).
 *
 * @return array<int, string>
 */
function su_finv2_tldr_paragraphs() {
	return array(
		'SearchUnify and Fin AI (formerly Intercom, acquired by Salesforce in June 2026 for $3.6B) solve fundamentally different problems. Fin is a chat-first conversational agent priced at $0.99 per resolution, locked to its proprietary Apex model, with 15–20 connectors centered on the Intercom/Salesforce ecosystem. SearchUnify is an enterprise agentic platform with fixed annual licensing, LLM-agnostic (10+ models), 100+ connectors across CRM/ITSM/KM/LMS, plus dedicated AI agents for knowledge health, escalation prediction, and case quality auditing.',
		'If your priority is building a vendor-neutral AI support platform that continuously improves enterprise knowledge, offers predictable licensing, supports multiple AI models, and integrates across your technology stack, SearchUnify provides a broader operational approach.',
	);
}

/**
 * Canonical TL;DR copy (single string for meta/schema).
 *
 * @return string
 */
function su_finv2_tldr_text() {
	return implode( ' ', su_finv2_tldr_paragraphs() );
}

/**
 * Meta description derived from TL;DR.
 *
 * @return string
 */
function su_finv2_meta_description() {
	$desc = wp_strip_all_tags( su_finv2_tldr_text() );
	$desc = preg_replace( '/\s+/', ' ', $desc );
	return wp_html_excerpt( trim( (string) $desc ), 155, '…' );
}

/**
 * Minimal field bag — title for meta description, form_id for Marketo.
 *
 * @return array<string, mixed>
 */
function su_finv2_fields() {
	static $fields = null;
	if ( null !== $fields ) {
		return $fields;
	}

	$fields = array(
		'title'      => get_the_title(),
		'subtitle'   => su_finv2_meta_description(),
		'form_id'    => '7377',
		'form_title' => __( 'Talk to an Expert', 'seoinux-child' ),
	);

	return $fields;
}

/**
 * Fin comparison table of contents.
 *
 * @return array<int, array{id: string, label: string}>
 */
function su_finv2_toc() {
	return array(
		array(
			'id'    => 'why-su',
			'label' => 'The Salesforce Acquisition Changes the Evaluation Conversation',
		),
		array(
			'id'    => 'strategic-questions',
			'label' => 'Four Strategic Questions Every Enterprise Buyer Should Ask',
		),
		array(
			'id'    => 'salesforce-context',
			'label' => 'Understanding the Salesforce Context',
		),
		array(
			'id'    => 'comparison',
			'label' => 'SearchUnify vs Fin Feature Comparison',
		),
		array(
			'id'    => 'product-experience',
			'label' => 'Product Experience - Customers\' Ratings',
		),
		array(
			'id'    => 'options',
			'label' => 'Migration to SearchUnify',
		),
		array(
			'id'    => 'faq',
			'label' => 'Frequently Asked Questions',
		),
	);
}

/**
 * Strategic Questions section — four enterprise buyer questions.
 *
 * @return array<int, array{label: string, question: string, body: string}>
 */
function su_finv2_strategic_questions() {
	return array(
		array(
			'label'    => 'Product Direction',
			'question' => 'How will the product evolve as part of Salesforce\'s broader AI and customer service strategy?',
			'body'     => 'Enterprise buyers should understand how future roadmap priorities may influence product innovation, integrations, and investment areas over time.',
			'icon'     => 'product-direction.svg',
		),
		array(
			'label'    => 'Platform Flexibility',
			'question' => 'How important is maintaining flexibility across CRM platforms, AI models, and enterprise applications?',
			'body'     => 'Organizations committed to a single ecosystem may prioritize deep native integration, while others may value the ability to adapt as business requirements evolve.',
			'icon'     => 'platform-flexibility.svg',
		),
		array(
			'label'    => 'Cost Predictability',
			'question' => 'How will AI costs scale as adoption expands across customers, agents, channels, and business units?',
			'body'     => 'Pricing models that work well during pilot deployments should also be evaluated for long-term operational planning.',
			'icon'     => 'cost-predictibility.svg',
		),
		array(
			'label'    => 'Knowledge Strategy',
			'question' => 'Does the platform simply answer questions, or does it continuously improve the enterprise knowledge that powers every future interaction?',
			'body'     => 'For many organizations, long-term AI success depends as much on knowledge maturity as on conversational automation.',
			'icon'     => 'knowledge-strategy.svg',
		),
	);
}

/**
 * Salesforce Context section paragraphs.
 *
 * @return array<int, string>
 */
function su_finv2_salesforce_context_paragraphs() {
	return array(
		'Salesforce has consistently expanded its customer experience portfolio through acquisitions and platform integration. Over time, acquired technologies have followed different paths. Some have remained standalone offerings for extended periods, while others have been integrated, rebranded, or incorporated into broader Salesforce platform capabilities.',
		'Each acquisition is unique, and Fin\'s long-term roadmap will ultimately be shaped by Salesforce\'s strategic priorities. Rather than assuming a specific outcome, enterprise buyers should understand how platform strategy may influence future product direction.',
		'For organizations already standardized on Salesforce, deeper integration may create additional value.',
		'For organizations operating across multiple CRM, ITSM, knowledge management, and collaboration platforms, maintaining architectural flexibility may remain an important evaluation criterion.',
	);
}

/**
 * Four-step Fin migration section.
 *
 * @return array<int, array{title: string, description: string, image: string}>
 */
function su_finv2_migration_steps() {
	return array(
		array(
			'title'       => 'Assess',
			'description' => 'Review your current Fin setup, knowledge sources, integrations, and support workflows to build a tailored migration plan.',
			'image'       => 'Assess.svg',
		),
		array(
			'title'       => 'Connect',
			'description' => 'Integrate SearchUnify with your existing knowledge repositories and business systems using native connectors.',
			'image'       => 'Connect.svg',
		),
		array(
			'title'       => 'Optimize',
			'description' => 'Configure AI search, relevance, permissions, and experiences to match your support operations and business goals.',
			'image'       => 'Optimize.svg',
		),
		array(
			'title'       => 'Go Live',
			'description' => 'Validate performance, train teams, and launch with confidence while continuously optimizing AI outcomes through analytics.',
			'image'       => 'go-live.svg',
		),
	);
}

/**
 * Fin product experience ratings (same SearchUnify customer ratings as Forethought).
 *
 * @return array<int, array{value: string, label: string, image: string, inner_style: string}>
 */
function su_finv2_experience_ratings() {
	return array(
		array(
			'value'       => '99%',
			'label'       => 'Security Protects',
			'image'       => '99-percentage.svg',
			'inner_style' => '',
		),
		array(
			'value'       => '98%',
			'label'       => 'Enables Productivity',
			'image'       => '98-percentage.svg',
			'inner_style' => '',
		),
		array(
			'value'       => '94%',
			'label'       => 'Reliable',
			'image'       => '94-percentage.svg',
			'inner_style' => '',
		),
		array(
			'value'       => '95%+',
			'label'       => 'Net Emotional Footprint',
			'image'       => '+95.svg',
			'inner_style' => 'width: 131px;',
		),
	);
}

/**
 * Fin comparison FAQ copy.
 *
 * @return array<int, array{q: string, a: string}>
 */
function su_finv2_faq() {
	return array(
		array(
			'q' => 'What is the difference between SearchUnify and Fin?',
			'a' => 'SearchUnify is an enterprise AI support platform that combines AI search, agent assistance, knowledge management, analytics, workflow automation, and enterprise integrations. Fin primarily focuses on AI-powered conversational support and customer interactions.',
		),
		array(
			'q' => 'Should organizations reconsider Fin after the Salesforce acquisition?',
			'a' => 'The acquisition does not change Fin\'s current capabilities, but enterprise buyers may want to evaluate future roadmap direction, ecosystem alignment, pricing, and long-term platform flexibility before making strategic investments.',
		),
		array(
			'q' => 'Is SearchUnify limited to a specific CRM?',
			'a' => 'No. SearchUnify is platform agnostic and integrates with Salesforce, ServiceNow, Zendesk, Microsoft Dynamics, Jira, Confluence, SharePoint, and more than 100 enterprise applications.',
		),
		array(
			'q' => 'Which platform is better for enterprises with multiple knowledge sources?',
			'a' => 'Organizations managing knowledge across multiple repositories typically benefit from platforms that provide unified enterprise search, centralized governance, and cross-platform integrations. SearchUnify is designed to support these complex enterprise environments.',
		),
		array(
			'q' => 'What happens to Intercom Fin customers after the Salesforce acquisition?',
			'a' => 'Intercom rebranded to Fin in May 2026, and Salesforce signed a definitive agreement to acquire Fin for approximately $3.6 billion on June 15, 2026, with closing expected in Q4 of Salesforce fiscal year 2027. Fin customers should expect roadmap convergence with Agentforce, potential pricing-model changes, and tighter dependence on the Salesforce ecosystem.',
		),
	);
}

/**
 * All FAQ items for schema.
 *
 * @return array<int, array{q: string, a: string}>
 */
function su_finv2_faq_all() {
	return su_finv2_faq();
}

/**
 * Comparison table summaries for structured data.
 *
 * @return array<int, array{category: string, searchunify: string, fin: string}>
 */
function su_finv2_comparison_rows() {
	return array(
		array(
			'category'    => 'Enterprise AI Search',
			'searchunify' => '✅ Unified search across 60+ enterprise systems',
			'fin'         => 'Limited to Intercom knowledge and connected sources',
		),
		array(
			'category'    => 'AI Agent Assistance',
			'searchunify' => '✅ Context-aware agent copilot with enterprise knowledge',
			'fin'         => 'AI assistance inside Intercom',
		),
		array(
			'category'    => 'Intelligent Self-Service',
			'searchunify' => '✅ Search, AI answers, guided workflows, request deflection',
			'fin'         => 'AI chatbot-first experience',
		),
		array(
			'category'    => 'Knowledge Management',
			'searchunify' => '✅ Continuous knowledge improvement and governance',
			'fin'         => 'Basic knowledge management',
		),
		array(
			'category'    => 'Multi-Repository Search',
			'searchunify' => '✅ Yes',
			'fin'         => 'Limited',
		),
		array(
			'category'    => 'Enterprise Integrations',
			'searchunify' => '✅ 100+ Out-of-the-Box connectors',
			'fin'         => 'Primarily Intercom ecosystem',
		),
		array(
			'category'    => 'AI Analytics',
			'searchunify' => '✅ Search analytics, content gaps, AI performance insights, Value Realization and ROI',
			'fin'         => 'Conversation analytics',
		),
		array(
			'category'    => 'Workflow Automation',
			'searchunify' => '✅ Built-in automation and orchestration',
			'fin'         => 'Limited support automation',
		),
		array(
			'category'    => 'Enterprise Governance',
			'searchunify' => '✅ Enterprise-grade permissions and access controls',
			'fin'         => 'Available within Intercom environment',
		),
		array(
			'category'    => 'Best Fit',
			'searchunify' => 'Large enterprises with complex support ecosystems',
			'fin'         => 'Organizations primarily using Intercom',
		),
	);
}

/**
 * @return string
 */
function su_finv2_page_url() {
	$permalink = get_permalink();
	return $permalink ? $permalink : home_url( '/comparison/fin/' );
}

/**
 * FAQPage JSON-LD for the Fin comparison page.
 *
 * @return array<string, mixed>
 */
function su_finv2_faq_schema() {
	$main_entity = array();

	foreach ( su_finv2_faq_all() as $faq ) {
		$main_entity[] = array(
			'@type'          => 'Question',
			'name'           => $faq['q'],
			'acceptedAnswer' => array(
				'@type' => 'Answer',
				'text'  => $faq['a'],
			),
		);
	}

	return array(
		'@type'      => 'FAQPage',
		'@id'        => su_finv2_page_url() . '#faq',
		'isPartOf'   => array(
			'@id' => su_finv2_page_url() . '#webpage',
		),
		'mainEntity' => $main_entity,
	);
}

/**
 * Comparison categories as ItemList JSON-LD.
 *
 * @return array<string, mixed>
 */
function su_finv2_comparison_schema() {
	$items = array();

	foreach ( su_finv2_comparison_rows() as $index => $row ) {
		$items[] = array(
			'@type'    => 'ListItem',
			'position' => $index + 1,
			'name'     => $row['category'],
			'description' => sprintf(
				'SearchUnify: %s Fin: %s',
				$row['searchunify'],
				$row['fin']
			),
		);
	}

	return array(
		'@type'           => 'ItemList',
		'@id'             => su_finv2_page_url() . '#comparison',
		'name'            => 'SearchUnify vs Fin platform comparison',
		'isPartOf'        => array(
			'@id' => su_finv2_page_url() . '#webpage',
		),
		'itemListElement' => $items,
	);
}

/**
 * Combined JSON-LD graph for the Fin comparison page.
 *
 * @return array<string, mixed>
 */
function su_finv2_schema_graph() {
	$page_url = su_finv2_page_url();

	return array(
		'@context' => 'https://schema.org',
		'@graph'   => array(
			array(
				'@type'           => 'WebPage',
				'@id'             => $page_url . '#webpage',
				'url'             => $page_url,
				'name'            => 'SearchUnify vs Fin',
				'description'     => su_finv2_tldr_text(),
				'dateModified'    => su_finv2_content_modified_iso(),
				'inLanguage'      => 'en-US',
				'speakable'       => array(
					'@type'       => 'SpeakableSpecification',
					'cssSelector' => array(
						'#tldr .cks-section-sub-head',
						'.su-cmpv2-faq__answer p',
					),
				),
				'mainEntity'      => array(
					array( '@id' => $page_url . '#faq' ),
					array( '@id' => $page_url . '#comparison' ),
				),
			),
			su_finv2_faq_schema(),
			su_finv2_comparison_schema(),
		),
	);
}
