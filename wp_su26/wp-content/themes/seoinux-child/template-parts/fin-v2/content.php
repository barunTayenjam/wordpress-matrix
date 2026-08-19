<?php

/**
 * Fin V2 — page body. All copy hardcoded (no ACF).
 *
 * Coverage:
 *   - Banner, TL;DR, TOC, §1 (why-su/Salesforce Acquisition): Fin-specific copy ✅
 *   - strategic-questions, salesforce-context sections: TODO stubs 🚧
 *   - why-cards, comparison-table rows, testimonials, options/migration,
 *     product-experience, cta, faq: Forethought placeholder — replace before go-live.
 *   - External URLs (Trustpilot/G2 review links, banner bg) need Fin-specific替换.
 *
 * Section order: banner -> tldr -> toc -> why-su -> strategic-questions ->
 *                salesforce-context -> comparison -> product-experience ->
 *                options -> cta -> faq
 *
 * @package SearchUnify
 */

if (! defined('ABSPATH')) {
	exit;
}

$uri   = get_stylesheet_directory_uri();
$arrow = '<i class="bi-arrow-up-right"></i>';
$check = '<img class="su-cmpv2-tick" src="' . esc_url( $uri ) . '/assets/img/cmpv2-tick.svg" alt="Yes" width="18" height="18" />';
$faqs  = su_finv2_faq();
$toc   = su_finv2_toc();
$tldr  = su_finv2_tldr_paragraphs();
?>

<section class="banner ckc-banner">
	<div class="su-container">
		<h1>SearchUnify vs Fin</h1>
		<h2 class="sub-head-ckc">Which Enterprise AI Support Platform Is Better for Long-Term Growth?</h2>
		<p class="cks-section-sub-head">Experience the #1 Ranked Enterprise Search Platform</p>
		<?php echo do_shortcode('[su_marketo_form id="7377" class="ckc-marketo-form-cta"]'); ?>
	</div>
	<?php su_cmpv2_render_banner_icons( 'Fin AI assistant' ); ?>
</section>

<section class="su-cmpv2-tldr" id="tldr">
	<div class="container su-container">
		<h2 class="cks-section-head"><?php echo esc_html( su_finv2_tldr_heading() ); ?></h2>
		<?php foreach ( $tldr as $paragraph ) : ?>
			<p class="cks-section-sub-head"><?php echo esc_html( $paragraph ); ?></p>
		<?php endforeach; ?>
	</div>
</section>

<section class="su-cmpv2-toc" id="table-of-contents" aria-label="Table of contents">
	<div class="container su-container">
		<h2 class="cks-section-head">Table of Contents</h2>
		<div class="su-cmpv2-toc__inner">
			<div class="su-cmpv2-toc__visual">
				<img src="<?php echo esc_url($uri); ?>/assets/img/table-of-content.webp" alt="Table of contents illustration" width="480" height="337" loading="lazy" decoding="async">
			</div>
			<nav class="su-cmpv2-toc__nav" aria-label="Page sections">
				<ol class="su-cmpv2-toc__list">
					<?php foreach ($toc as $item) : ?>
						<li>
							<a href="#<?php echo esc_attr($item['id']); ?>">
								<span class="su-cmpv2-faq__icon su-cmpv2-faq__icon--closed su-cmpv2-toc__icon" aria-hidden="true"><i class="bi bi-arrow-up-right-circle-fill"></i></span>
								<span class="su-cmpv2-toc__label"><?php echo esc_html($item['label']); ?></span>
							</a>
						</li>
					<?php endforeach; ?>
				</ol>
			</nav>
		</div>
	</div>
</section>

<section class="choose-su" id="why-su">
	<div class="su-container">
		<h2 class="cks-section-head">The Salesforce Acquisition Changes the Evaluation Conversation</h2>
		<p class="cks-section-sub-head">The announced acquisition of Fin by Salesforce represents one of the most significant developments in the customer support technology market. While Fin's core capabilities remain unchanged today, the acquisition naturally introduces new strategic considerations for organizations making long-term technology investments.</p>
		<p class="cks-section-sub-head">Enterprise support leaders are no longer evaluating conversational AI alone. They are asking broader questions about platform evolution, ecosystem alignment, operational flexibility, and future investment strategy.</p>
		<p class="cks-section-sub-head">Instead of focusing only on today's feature set, buyers should consider how their chosen platform will support their business over the next three to five years.</p>
	</div>
</section>

<section class="choose-su" id="strategic-questions">
	<div class="su-container">
		<h2 class="cks-section-head">Four Strategic Questions Every Enterprise Buyer Should Ask</h2>
		<div class="why-cards-row">
			<?php foreach ( su_finv2_strategic_questions() as $item ) : ?>
				<div class="why-card">
					<img class="why-card-icon" src="<?php echo esc_url( $uri . '/assets/img/' . $item['icon'] ); ?>" alt="<?php echo esc_attr( $item['label'] ); ?>" width="56" height="56" loading="lazy">
					<h3><?php echo esc_html( $item['label'] ); ?></h3>
					<h4 class="why-card-subtitle"><?php echo esc_html( $item['question'] ); ?></h4>
					<p class="why-card-body"><?php echo esc_html( $item['body'] ); ?></p>
				</div>
			<?php endforeach; ?>
		</div>
	</div>
</section>

<section class="choose-su" id="salesforce-context">
	<div class="su-container">
		<h2 class="cks-section-head">Understanding the Salesforce Context</h2>
		<?php foreach ( su_finv2_salesforce_context_paragraphs() as $paragraph ) : ?>
			<p class="cks-section-sub-head"><?php echo esc_html( $paragraph ); ?></p>
		<?php endforeach; ?>
	</div>
</section>

<section class="comparison-section" id="comparison">
	<div class="container su-container">
		<h2 class="cks-section-head">What Enterprise Teams Need Beyond Bot</h2>
		<div class="page-agentic-rag">
			<div class="comparison-wrapper">
				<table class="comparison-table">
					<caption class="visually-hidden">SearchUnify vs Intercom Fin capability comparison</caption>
					<colgroup>
						<col class="col-category">
						<col>
						<col>
					</colgroup>
					<thead>
						<tr class="comparison-header">
							<th scope="col" class="category-label">Capability</th>
							<th scope="col" class="col-2">SearchUnify</th>
							<th scope="col" class="col-3">Intercom Fin</th>
						</tr>
					</thead>
					<tbody>
						<?php
						$cmp_rows = su_finv2_comparison_rows();
						$cmp_last = count( $cmp_rows ) - 1;
						foreach ( $cmp_rows as $i => $row ) :
							$cls = 'label';
							if ( 0 === $i ) {
								$cls .= ' label--first';
							}
							if ( $i === $cmp_last ) {
								$cls .= ' label--last';
							}
							?>
							<tr>
								<th scope="row" class="<?php echo esc_attr( $cls ); ?>"><?php echo esc_html( $row['category'] ); ?></th>
								<td class="col-2"><?php
								$su_cell = (string) $row['searchunify'];
								if ( str_starts_with( $su_cell, '✅' ) ) {
									echo '<span class="su-cmpv2-tick-cell">';
									echo $check; // phpcs:ignore WordPress.Security.EscapeOutput.OutputNotEscaped
									echo '<span>' . esc_html( ltrim( substr( $su_cell, strlen( '✅' ) ) ) ) . '</span>';
									echo '</span>';
								} else {
									echo esc_html( $su_cell );
								}
								?></td>
								<td class="col-3"><?php echo esc_html( $row['fin'] ); ?></td>
							</tr>
						<?php endforeach; ?>
					</tbody>
				</table>
			</div>
		</div>
	</div>
</section>

<section class="wrapper su-container" id="product-experience">
	<h2 class="cks-section-head">Product Experience</h2>
	<p class="subtitle">Customers' Ratings</p>
	<div class="grid">
		<?php foreach ( su_finv2_experience_ratings() as $rating ) : ?>
			<div class="item">
				<div class="inner"<?php echo $rating['inner_style'] ? ' style="' . esc_attr( $rating['inner_style'] ) . '"' : ''; ?>>
					<img src="<?php echo esc_url( $uri . '/assets/img/' . $rating['image'] ); ?>" alt="<?php echo esc_attr( $rating['value'] . ' ' . $rating['label'] ); ?>" width="140" height="140" loading="lazy">
				</div>
				<p><?php if ( 'Net Emotional Footprint' === $rating['label'] ) : ?>Net Emotional<br>Footprint<?php else : ?><?php echo esc_html( $rating['label'] ); ?><?php endif; ?></p>
			</div>
		<?php endforeach; ?>
	</div>
	<div class="brand"><img src="<?php echo esc_url( $uri ); ?>/assets/img/review.svg" alt="SoftwareReviews" width="160" height="40" loading="lazy"></div>
</section>

<section class="options-section" id="options">
		<div class="container su-container">
			<h2 class="cks-section-head">Concerned About Migration?<br>A Structured Path from Fin to SearchUnify.</h2>
		<div class="options">
			<?php foreach ( su_finv2_migration_steps() as $step ) : ?>
				<div class="option-card">
					<img class="option-image" loading="lazy" src="<?php echo esc_url( $uri . '/assets/img/' . $step['image'] ); ?>" alt="<?php echo esc_attr( $step['title'] ); ?>">
					<p class="option-card-head"><?php echo esc_html( $step['title'] ); ?></p>
					<p class="option-card-content"><?php echo esc_html( $step['description'] ); ?></p>
				</div>
			<?php endforeach; ?>
		</div>
		<div class="option-cta">
			<a class="ckc-cta" href="https://www.searchunify.com/company/contact-us">Talk to Professional Support<?php echo $arrow; // phpcs:ignore
																																																						?></a>
		</div>
	</div>
</section>

<section class="cta-section" id="live-demo">
	<div class="cta-card container su-container">
		<h2 class="cta-heading">AI Can Resolve Tickets.</h2>
		<p class="cta-subtext">The Real Question Is:</p>
		<p class="cta-subtext">Will your support organization learn from them?</p>
		<p class="cta-subtext">See how SearchUnify helps enterprises transform support interactions into knowledge, intelligence, and long-term operational advantage.</p>
		<a class="ckc-cta" href="https://www.searchunify.com/request-demo/" aria-label="Navigate to Book a Personalized Demo" title="Navigate to Book a Personalized Demo">Book a Personalized Demo<?php echo $arrow; // phpcs:ignore
																																								 ?></a>
	</div>
</section>

<section class="su-cmpv2-faq" id="faq">
	<div class="container su-container">
		<div class="su-cmpv2-faq__cols">
			<div class="su-cmpv2-faq__aside">
				<div class="su-cmpv2-faq__heading-card">
					<h2 class="cks-section-head">Frequently Asked Questions</h2>
				</div>
				<h3 class="su-cmpv2-faq__help-title">Still Need Assistance?</h3>
				<a class="su-cmpv2-faq__box" href="https://docs.searchunify.com/" target="_blank" rel="noopener">
					<span class="su-cmpv2-faq__box-icon" aria-hidden="true"><i class="bi bi-headset"></i></span>
					<span class="su-cmpv2-faq__box-title">Help center</span>
				</a>
				<a class="su-cmpv2-faq__box" href="https://community.searchunify.com/hc/en-us" target="_blank" rel="noopener">
					<span class="su-cmpv2-faq__box-icon" aria-hidden="true"><i class="bi bi-chat-dots"></i></span>
					<span class="su-cmpv2-faq__box-title">Community</span>
				</a>
			</div>
			<div class="su-cmpv2-faq__list">
				<?php foreach ($faqs as $i => $faq) : ?>
					<details class="su-cmpv2-faq__item" <?php echo 0 === $i ? 'open' : ''; ?>>
						<summary>
							<span class="su-cmpv2-faq__icon su-cmpv2-faq__icon--closed" aria-hidden="true"><i class="bi bi-arrow-up-right-circle-fill"></i></span>
							<span class="su-cmpv2-faq__icon su-cmpv2-faq__icon--open" aria-hidden="true"><i class="bi bi-arrow-down-right-circle-fill"></i></span>
							<h3 class="su-cmpv2-faq__question"><?php echo esc_html( $faq['q'] ); ?></h3>
						</summary>
						<div class="su-cmpv2-faq__answer">
							<p><?php echo esc_html($faq['a']); ?></p>
						</div>
					</details>
				<?php endforeach; ?>
			</div>
		</div>
	</div>
</section>
