---
description: Use when developing Moodle themes — Boost child themes, theme/yourtheme/config.php, SCSS pre/post hooks, layouts, Mustache template overrides, theme settings, $OUTPUT renderer overrides, and theme designer mode.
tools: ['codebase', 'search', 'editFiles', 'runCommands']
---
# Moodle Theme Development

## Overview

Moodle themes live under `theme/<name>/`. Almost all custom themes inherit from **Boost** (the bundled Bootstrap 5–based theme since 4.0). Override SCSS, layouts, and templates rather than building from scratch.

## When to Use

- Branding a Moodle install (logo, colors, fonts)
- Adding theme-level layout overrides
- Overriding a core Mustache template
- Adding theme settings (admin can configure)
- Per-tenant theming via category themes

**Skip when:** changing plugin UI — modify the plugin's own templates/SCSS.

## Theme skeleton

```
theme/yourtheme/
  config.php                    # required: theme manifest
  version.php                   # required: component, version, requires
  lib.php                       # SCSS hooks, post-process callbacks
  settings.php                  # admin settings
  lang/en/theme_yourtheme.php   # required: pluginname
  scss/
    pre.scss                    # injected BEFORE Boost SCSS (variables)
    post.scss                   # injected AFTER Boost SCSS (overrides)
    preset/                     # full preset alternatives
  layout/
    columns2.php                # override Boost's two-column layout
    drawers.php                 # 4.0+ default layout
    columns1.php
    secure.php
    embedded.php
    login.php
    maintenance.php
  templates/                    # override core Mustache (mirror path)
    core/
      navbar.mustache
  classes/
    output/
      core_renderer.php         # extend Boost's core_renderer
  pix/
    favicon.ico
    logo.png
```

## config.php

```php
<?php
defined('MOODLE_INTERNAL') || die();

$THEME->name             = 'yourtheme';
$THEME->parents          = ['boost'];                           // inherit
$THEME->sheets           = [];                                  // CSS files (SCSS preferred)
$THEME->editor_sheets    = [];
$THEME->scss             = function($theme) {
    return theme_yourtheme_get_main_scss_content($theme);       // see lib.php
};
$THEME->layouts          = [
    // override only the layouts you change; rest inherit from Boost
    'frontpage' => [
        'file' => 'columns2.php',
        'regions' => ['side-pre'],
        'defaultregion' => 'side-pre',
    ],
];
$THEME->enable_dock      = false;
$THEME->yuicssmodules    = [];
$THEME->rendererfactory  = 'theme_overridden_renderer_factory';
$THEME->prescsscallback  = 'theme_yourtheme_get_pre_scss';
$THEME->extrascsscallback = 'theme_yourtheme_get_extra_scss';
$THEME->iconsystem       = \core\output\icon_system::FONTAWESOME;
$THEME->haseditswitch    = true;
$THEME->usescourseindex  = true;
$THEME->precompiledcsscallback = 'theme_yourtheme_get_precompiled_css';
$THEME->addblockposition = BLOCK_ADDBLOCK_POSITION_FLATNAV;
```

## lib.php — SCSS pipeline

```php
<?php
defined('MOODLE_INTERNAL') || die();

function theme_yourtheme_get_main_scss_content($theme): string {
    global $CFG;
    $boost = file_get_contents($CFG->dirroot . '/theme/boost/scss/preset/default.scss');
    $custom = file_get_contents(__DIR__ . '/scss/post.scss');
    return $boost . "\n" . $custom;
}

function theme_yourtheme_get_pre_scss($theme): string {
    $scss = '';
    $configurable = [
        'brandcolor' => ['primary'],
    ];
    foreach ($configurable as $configkey => $vars) {
        $value = $theme->settings->{$configkey} ?? null;
        if (empty($value)) {
            continue;
        }
        foreach ($vars as $var) {
            $scss .= '$' . $var . ': ' . $value . ";\n";
        }
    }
    $scss .= file_get_contents(__DIR__ . '/scss/pre.scss');
    return $scss;
}

function theme_yourtheme_get_extra_scss($theme): string {
    return $theme->settings->scss ?? '';
}
```

`pre.scss` runs before Boost — defines variables (`$primary`, `$body-bg`, etc.).
`post.scss` runs after — overrides classes that already exist.

## Theme settings

`settings.php`:

```php
<?php
defined('MOODLE_INTERNAL') || die();

if ($ADMIN->fulltree) {
    $settings = new theme_boost_admin_settingspage_tabs(
        'themesettingyourtheme',
        get_string('configtitle', 'theme_yourtheme')
    );

    // General tab
    $page = new admin_settingpage('theme_yourtheme_general',
        get_string('generalsettings', 'theme_boost'));

    // Color
    $page->add(new admin_setting_configcolourpicker(
        'theme_yourtheme/brandcolor',
        get_string('brandcolor', 'theme_yourtheme'),
        get_string('brandcolor_desc', 'theme_yourtheme'),
        '#0f6fc5'
    ));

    // Logo
    $page->add(new admin_setting_configstoredfile(
        'theme_yourtheme/logo',
        get_string('logo', 'theme_yourtheme'),
        get_string('logo_desc', 'theme_yourtheme'),
        'logo', 0,
        ['maxfiles' => 1, 'accepted_types' => ['.png', '.svg']]
    ));

    // Raw SCSS
    $page->add(new admin_setting_scsscode(
        'theme_yourtheme/scss',
        get_string('rawscss', 'theme_boost'),
        get_string('rawscss_desc', 'theme_boost'),
        '',
        PARAM_RAW
    ));

    $settings->add($page);
}
```

## Layout files

`layout/columns2.php` controls page structure:

```php
<?php
require_once($CFG->dirroot . '/theme/boost/layout/common.php');

$secondarynavigation = false;
$overflow = '';
if ($PAGE->has_secondary_navigation()) {
    $secondarynavigation = true;
    // ...
}

$templatecontext = [
    'sitename' => format_string($SITE->fullname),
    'output' => $OUTPUT,
    'sidepreblocks' => $blockshtml,
    'hasblocks' => strpos($blockshtml, 'data-block=') !== false,
    'bodyattributes' => $bodyattributes,
    'secondarynavigation' => $secondarynavigation,
];

echo $OUTPUT->render_from_template('theme_yourtheme/columns2', $templatecontext);
```

Mustache layout at `templates/columns2.mustache` — copy from Boost and modify.

## Renderer override

`classes/output/core_renderer.php`:

```php
<?php
namespace theme_yourtheme\output;
defined('MOODLE_INTERNAL') || die();

class core_renderer extends \theme_boost\output\core_renderer {
    public function favicon(): \moodle_url {
        $logo = $this->page->theme->setting_file_url('favicon', 'favicon');
        return $logo ? new \moodle_url($logo) : parent::favicon();
    }
}
```

Activated by `$THEME->rendererfactory = 'theme_overridden_renderer_factory';` in `config.php`.

## Template override

To override `core/navbar.mustache`, copy to `theme/yourtheme/templates/core/navbar.mustache`. Moodle resolves theme templates first.

## Theme designer mode (DEV ONLY)

```php
// config.php
$CFG->themedesignermode = true;
```

Disables CSS caching — every page rebuilds SCSS. **Never** in production — kills performance.

After changing SCSS in production: Site admin > Development > Purge caches > "Theme caches".

## SCSS variables (Boost defaults)

```scss
// pre.scss — override before Boost imports
$primary:   #0f6fc5;
$secondary: #6c757d;
$success:   #5cb85c;
$danger:    #d9534f;
$warning:   #f0ad4e;
$info:      #5bc0de;
$body-bg:   #fff;
$body-color: #1d2125;
$font-family-sans-serif: 'Inter', sans-serif;
$navbar-height: 60px;
```

Full list: `theme/boost/scss/moodle/_variables.scss`.

## Per-category / per-cohort theme

Site admin > Appearance > Themes > Theme settings:
- Allow theme changes per-course/category
- `$THEME->allowedscss` for tenant-controlled SCSS

Programmatic:

```php
$category = $DB->get_record('course_categories', ['id' => $catid]);
$category->theme = 'yourtheme';
$DB->update_record('course_categories', $category);
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Editing Boost directly | Create child theme inheriting Boost |
| Theme designer mode in production | Disable, purge theme caches |
| Forgetting `theme_overridden_renderer_factory` | Renderer overrides won't load |
| Heavy logic in `lib.php` SCSS callback | Cache via `precompiledcsscallback` |
| Hardcoded colors in templates | Use CSS variables / SCSS vars from pre.scss |
| Bumping `version.php` not enough | Also purge caches: `php admin/cli/purge_caches.php` |
| Missing FontAwesome icon system | `$THEME->iconsystem = \core\output\icon_system::FONTAWESOME` |
| Layout file echoes raw HTML | Render via Mustache for theme overridability |
| SCSS contrast ratios fail AA | See `moodle-accessibility` skill |
| Logo / favicon as raw URL | Use `admin_setting_configstoredfile` + `setting_file_url` |

## Build + cache

```bash
# After SCSS changes (production)
php admin/cli/purge_caches.php

# Theme designer mode (dev) — auto-rebuild
# config.php: $CFG->themedesignermode = true;

# Build SCSS to CSS once for inspection
php admin/cli/build_theme_css.php --themes=yourtheme
```

## References

- Themes: https://moodledev.io/docs/apis/plugintypes/theme
- Boost theme: https://moodledev.io/docs/apis/plugintypes/theme/boost
- SCSS: https://moodledev.io/docs/apis/plugintypes/theme#scss
- Layouts: https://moodledev.io/docs/apis/plugintypes/theme/layouts
- Theme settings: https://moodledev.io/docs/apis/plugintypes/theme/settings
- Override templates: https://moodledev.io/docs/apis/subsystems/output/templates#overriding-templates
