# moodle-mobile-app

> Use when integrating a Moodle plugin with the Moodle Mobile app — db/mobile.php remote templates, Ionic/Angular components delivered server-side, mobile.php view types, addons, push notifications, and offline support.

# Moodle Mobile App Integration

## Overview

Moodle Mobile app (Ionic/Angular) loads plugin UI as **remote templates** declared in `db/mobile.php`. The server returns Mustache-like templates + JS that the app renders inline. No app rebuild required — works on any user's installed app once the site declares the addon.

## When to Use

- Adding plugin UI to mobile app
- Surfacing notifications, dashboard items, or activity views in the app
- Offline-capable content
- Push notifications for plugin events

**Skip when:** plugin only used in browser admin UI.

## Architecture

```
Moodle server                          Moodle Mobile app
─────────────                          ─────────────────
db/mobile.php          ────────────►   Discovers addons via
classes/output/mobile.php              tool_mobile_get_plugins_supporting_mobile

Returns                ────────────►   Renders Ionic components
  templates (.html)
  initial JS
  styles
```

App calls a server function which returns:
- A Mustache-like template (Ionic + custom directives)
- Optional JS to run client-side
- Optional initial data
- Optional offline functions

## db/mobile.php

```php
<?php
defined('MOODLE_INTERNAL') || die();

$addons = [
    'local_example' => [
        'handlers' => [
            'mainmenu' => [
                'displaydata' => [
                    'title' => 'pluginname',
                    'icon'  => 'list',
                    'class' => '',
                ],
                'delegate'    => 'CoreMainMenuDelegate',
                'method'      => 'mobile_main_menu_view',
                'styles'      => [
                    'url'     => '/local/example/mobile/styles.css',
                    'version' => 1,
                ],
                'offlinefunctions' => [
                    'mobile_main_menu_view' => [],
                ],
            ],
            'courseoption' => [
                'displaydata' => [
                    'title' => 'attendance',
                    'class' => '',
                ],
                'delegate' => 'CoreCourseOptionsDelegate',
                'method'   => 'mobile_course_view',
            ],
        ],
        'lang' => [
            ['pluginname', 'local_example'],
            ['attendance', 'local_example'],
        ],
    ],
];
```

### Delegates

| Delegate | Where it shows |
|----------|----------------|
| `CoreMainMenuDelegate` | Main menu (bottom tab bar) |
| `CoreUserDelegate` | User profile page |
| `CoreCourseOptionsDelegate` | Course menu |
| `CoreCourseModuleDelegate` | Activity in course (for `mod_*` plugins) |
| `CoreBlockDelegate` | Sidebar block (for `block_*`) |
| `CoreSettingsDelegate` | App settings page |
| `CoreMessageOutputDelegate` | Message output handler |

## classes/output/mobile.php

```php
<?php
namespace local_example\output;
defined('MOODLE_INTERNAL') || die();

class mobile {

    public static function mobile_main_menu_view(array $args): array {
        global $DB, $USER;

        $items = $DB->get_records('local_example_items',
            ['userid' => $USER->id], 'timecreated DESC', '*', 0, 20);

        return [
            'templates' => [
                [
                    'id'   => 'main',
                    'html' => self::render_main_template(),
                ],
            ],
            'javascript' => self::get_javascript(),
            'otherdata'  => [
                'items' => json_encode(array_values($items)),
                'sesskey' => sesskey(),
            ],
            'files' => [],
        ];
    }

    private static function render_main_template(): string {
        return '
<ion-list>
    <ion-item-divider><ion-label>{{ \'plugin.local_example.attendance\' | translate }}</ion-label></ion-item-divider>
    <ion-item *ngFor="let item of CONTENT_OTHERDATA.items">
        <ion-label>
            <h2>{{ item.name }}</h2>
            <p>{{ item.timecreated | coreFormatDate }}</p>
        </ion-label>
        <ion-button slot="end" (click)="markPresent(item.id)">
            {{ \'plugin.local_example.markpresent\' | translate }}
        </ion-button>
    </ion-item>
</ion-list>';
    }

    private static function get_javascript(): string {
        return "
this.markPresent = (id) => {
    const params = {sessionid: id, userid: this.CoreSitesProvider.getCurrentSite().getUserId()};
    return this.CoreSitesProvider.getCurrentSite()
        .write('local_example_mark_present', params)
        .then((result) => {
            this.CoreDomUtilsProvider.showToast('plugin.local_example.marked', true, 2000);
        });
};";
    }
}
```

## Required web services

The function name in `db/mobile.php` (`'method' => 'mobile_main_menu_view'`) must be exposed as a web service in `db/services.php`:

```php
$functions = [
    'local_example_mobile_main_menu_view' => [
        'classname'    => 'local_example\output\mobile',
        'methodname'   => 'mobile_main_menu_view',
        'description'  => 'Main menu mobile view',
        'type'         => 'read',
        'capabilities' => '',
        'services'     => [MOODLE_OFFICIAL_MOBILE_SERVICE],
    ],
];
```

Plus the AJAX/REST functions used inside the template (`local_example_mark_present`).

## Template syntax

Mobile templates use Angular + Ionic with Moodle directives:

| Directive | Use |
|-----------|-----|
| `{{ 'plugin.local_example.foo' \| translate }}` | Lang string |
| `{{ value \| coreFormatDate }}` | Format unix timestamp |
| `{{ html \| coreFormatText }}` | Format Moodle text |
| `<core-format-text [text]="html" />` | Same, component form |
| `*ngFor="let item of CONTENT_OTHERDATA.items"` | Loop |
| `*ngIf="condition"` | Conditional |
| `(click)="handler()"` | Event |
| `<ion-item>`, `<ion-list>`, `<ion-button>` | Ionic UI |
| `<core-empty-box>` | "Nothing here" placeholder |

`CONTENT_OTHERDATA` = data passed via `'otherdata'`. Strings JSON-decoded automatically.

## JavaScript scope

Helpers injected into JS scope:

| Object | Use |
|--------|-----|
| `this.CoreSitesProvider` | Current site, current user, web service calls |
| `this.CoreDomUtilsProvider` | Toasts, alerts, modals |
| `this.CoreFilepoolProvider` | Cache files for offline |
| `this.CoreUtilsProvider` | Misc helpers |
| `this.refreshContent(false)` | Reload current view |

## Offline support

Add functions to `'offlinefunctions'`:

```php
'offlinefunctions' => [
    'mobile_main_menu_view' => [],
    'local_example_get_items' => [],
],
```

App pre-fetches results during sync — they survive offline. For mutations (mark present), use the offline write API:

```javascript
this.CoreSitesProvider.getCurrentSite().write(
    'local_example_mark_present',
    params,
    {forceOffline: false, getFromCache: false}
).catch((error) => {
    if (this.CoreUtilsProvider.isWebServiceError(error)) {
        return Promise.reject(error);
    }
    // Queue for later sync
    return this.CoreCourseProvider.storeOfflineAction(...);
});
```

## Push notifications

Push delivery via Moodle's airnotifier service. Plugin events trigger notifications via `\core\message\manager::send_message()`. Mobile app receives them automatically when:

- Site has airnotifier configured (Site admin > Mobile > Push notifications)
- User logged into mobile app
- User has the addon's notification preference enabled

## Testing

1. Local dev: install Moodle Mobile app, point at `http://10.0.2.2:8000` (Android emulator) or your LAN IP
2. Site admin > Mobile > Enable web services for mobile devices
3. Log in to app — addon appears
4. To force template re-fetch after server change: pull-to-refresh, or app settings > Synchronisation > Synchronise now
5. Browser-based dev: `npx ionic serve` against [`moodle-mobile-app`](https://github.com/moodlehq/moodleapp) source pointing at your site

## Styles

`local/example/mobile/styles.css` (referenced from `db/mobile.php`):

```css
.local_example-marked {
    color: var(--ion-color-success);
    font-weight: bold;
}
```

Bumping `'version' => N` in `db/mobile.php` invalidates app's cached styles.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Method not exposed as web service | Declare in `db/services.php` with `MOODLE_OFFICIAL_MOBILE_SERVICE` |
| Lang strings not declared in `db/mobile.php` | App can't render `{{ 'plugin...' | translate }}` |
| `<div>` instead of Ionic `<ion-*>` | Use Ionic components for native look |
| Forgetting `MOODLE_OFFICIAL_MOBILE_SERVICE` | Web service callable but not for mobile |
| Heavy DB queries on every refresh | Cache via MUC + invalidate on update |
| Hand-formatting timestamps | Use `coreFormatDate` filter |
| Embedding HTML directly | Use `coreFormatText` for `format_text`-equivalent escaping |
| No `offlinefunctions` for read views | Pre-fetch fails — declare them |
| Not bumping styles `version` | App keeps old CSS |
| Calling `fetch()` directly | Use `CoreSitesProvider` — handles auth + tokens |

## References

- Mobile addons: https://moodledev.io/general/app/development/plugins-development-guide
- Templates spec: https://moodledev.io/general/app/development/plugins-development-guide/templates
- Delegates list: https://moodledev.io/general/app/development/plugins-development-guide/api-reference
- Offline support: https://moodledev.io/general/app/development/plugins-development-guide/offline
- Push notifications: https://moodledev.io/general/app/development/plugins-development-guide/notifications
- App source: https://github.com/moodlehq/moodleapp
