# @capgo/capacitor-auto

<a href="https://capgo.app/"><img src="https://capgo.app/readme-banner.svg?repo=Cap-go/capacitor-auto" alt="Capgo - Instant updates for Capacitor" /></a>

<div align="center">
  <h2><a href="https://capgo.app/?ref=plugin_auto"> ➡️ Get Instant updates for your App with Capgo</a></h2>
  <h2><a href="https://capgo.app/consulting/?ref=plugin_auto"> Missing a feature? We’ll build the plugin for you 💪</a></h2>
</div>

Capacitor plugin for a small, template-safe bridge between your app and CarPlay / Android Auto.

## Install

```bash
npm install @capgo/capacitor-auto
npx cap sync
```

## What it does

- Sends a simple list template from the phone app to the car display.
- Emits `carAction` events when the driver selects a car UI row.
- Emits connection events when the car host connects or disconnects.
- Persists a small JSON state slice that native car code can read when the Capacitor app is not running.
- Provides native entry points for CarPlay and Android Auto templated apps.

## What it does not do

- It does not mirror a Capacitor WebView into the car display.
- It does not bypass Apple CarPlay entitlements, Google Play car app review, or driver-distraction template rules.
- It does not replace category-specific media, navigation, messaging, or calling APIs.

## Usage

```typescript
import { Auto } from '@capgo/capacitor-auto';

await Auto.setRootTemplate({
  title: 'Garage',
  sections: [
    {
      header: 'Doors',
      items: [
        {
          id: 'open-main-door',
          title: 'Open main door',
          subtitle: 'Tap to send the action to the phone app',
          payload: { doorId: 'main' },
        },
      ],
    },
  ],
});

await Auto.addListener('connectionChanged', (event) => {
  console.log('Car connected:', event.connected, event.platform);
});

await Auto.addListener('carAction', async (event) => {
  if (event.id === 'open-main-door') {
    await openGarageDoor(event.payload?.doorId);
  }
});
```

## Shared car state

Android Auto and CarPlay can start without the Capacitor WebView. Keep the car experience independent by writing the state it needs into the plugin store whenever the phone app has fresh data.

```typescript
await Auto.setState({
  key: 'navigation',
  value: {
    routeId: 'morning-commute',
    remainingDistanceMeters: 4200,
    instruction: 'Turn right in 300 meters',
  },
});

await Auto.addListener('stateChanged', (event) => {
  if (event.key === 'navigation') {
    console.log('Navigation state updated:', event.value);
  }
});
```

Native Android Auto or CarPlay code can read the same store directly through `AutoStore.get(context)` on Android and `AutoStore.shared` on iOS. The plugin also persists the last root template set with `setRootTemplate`, so a cold car session can render the most recent template before the web app wakes up.

## iOS setup

CarPlay apps require Apple approval for the matching CarPlay entitlement and must use Apple-approved CarPlay templates for the app category.

Add a CarPlay scene configuration to the app `Info.plist` and point its delegate to the plugin scene delegate. The exact module prefix depends on how the plugin is integrated:

- Swift Package Manager target: `AutoPlugin.AutoCarPlaySceneDelegate`
- CocoaPods module: `CapgoCapacitorAuto.AutoCarPlaySceneDelegate`

```xml
<key>UIApplicationSceneManifest</key>
<dict>
  <key>UIApplicationSupportsMultipleScenes</key>
  <true/>
  <key>UISceneConfigurations</key>
  <dict>
    <key>CPTemplateApplicationSceneSessionRoleApplication</key>
    <array>
      <dict>
        <key>UISceneClassName</key>
        <string>CPTemplateApplicationScene</string>
        <key>UISceneDelegateClassName</key>
        <string>AutoPlugin.AutoCarPlaySceneDelegate</string>
      </dict>
    </array>
  </dict>
</dict>
```

## Android setup

The plugin includes an Android Auto `CarAppService`, declares the `template` capability, and defaults to the `IOT` car app category. Your app still has to qualify for the declared car category before publishing on Google Play.

If your app uses another category, override the service declaration in your app manifest and use the category Google requires for your use case.

## Compatibility

| Plugin version | Capacitor compatibility | Maintained |
| -------------- | ----------------------- | ---------- |
| v8.\*.\*       | v8.\*.\*                | Yes        |

## API

<docgen-index>

* [`isAvailable()`](#isavailable)
* [`setRootTemplate(...)`](#setroottemplate)
* [`setState(...)`](#setstate)
* [`getState(...)`](#getstate)
* [`removeState(...)`](#removestate)
* [`setTransientState(...)`](#settransientstate)
* [`getTransientState(...)`](#gettransientstate)
* [`sendMessage(...)`](#sendmessage)
* [`getPluginVersion()`](#getpluginversion)
* [`addListener('connectionChanged', ...)`](#addlistenerconnectionchanged-)
* [`addListener('carAction', ...)`](#addlistenercaraction-)
* [`addListener('messageReceived', ...)`](#addlistenermessagereceived-)
* [`addListener('stateChanged', ...)`](#addlistenerstatechanged-)
* [`removeAllListeners()`](#removealllisteners)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### isAvailable()

```typescript
isAvailable() => Promise<AutoAvailability>
```

Returns whether the current platform supports this plugin and whether a car is connected.

**Returns:** <code>Promise&lt;<a href="#autoavailability">AutoAvailability</a>&gt;</code>

--------------------


### setRootTemplate(...)

```typescript
setRootTemplate(options: AutoTemplateOptions) => Promise<void>
```

Sets the root car template. Use this to push phone app state to the car display.

| Param         | Type                                                                |
| ------------- | ------------------------------------------------------------------- |
| **`options`** | <code><a href="#autotemplateoptions">AutoTemplateOptions</a></code> |

--------------------


### setState(...)

```typescript
setState(options: AutoStateOptions) => Promise<void>
```

Persists a JSON state slice that native Android Auto and CarPlay code can read even when the
Capacitor WebView is not alive.

| Param         | Type                                                          |
| ------------- | ------------------------------------------------------------- |
| **`options`** | <code><a href="#autostateoptions">AutoStateOptions</a></code> |

--------------------


### getState(...)

```typescript
getState(options: AutoStateKeyOptions) => Promise<AutoStateResult>
```

Reads a persisted JSON state slice.

| Param         | Type                                                                |
| ------------- | ------------------------------------------------------------------- |
| **`options`** | <code><a href="#autostatekeyoptions">AutoStateKeyOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#autostateresult">AutoStateResult</a>&gt;</code>

--------------------


### removeState(...)

```typescript
removeState(options: AutoStateKeyOptions) => Promise<void>
```

Removes a persisted JSON state slice.

| Param         | Type                                                                |
| ------------- | ------------------------------------------------------------------- |
| **`options`** | <code><a href="#autostatekeyoptions">AutoStateKeyOptions</a></code> |

--------------------


### setTransientState(...)

```typescript
setTransientState(options: AutoStateOptions) => Promise<void>
```

Stores a process-local JSON state slice and emits the same `stateChanged` event.

| Param         | Type                                                          |
| ------------- | ------------------------------------------------------------- |
| **`options`** | <code><a href="#autostateoptions">AutoStateOptions</a></code> |

--------------------


### getTransientState(...)

```typescript
getTransientState(options: AutoStateKeyOptions) => Promise<AutoStateResult>
```

Reads a process-local JSON state slice.

| Param         | Type                                                                |
| ------------- | ------------------------------------------------------------------- |
| **`options`** | <code><a href="#autostatekeyoptions">AutoStateKeyOptions</a></code> |

**Returns:** <code>Promise&lt;<a href="#autostateresult">AutoStateResult</a>&gt;</code>

--------------------


### sendMessage(...)

```typescript
sendMessage(options: AutoMessageOptions) => Promise<void>
```

Sends an application-defined message to the native car bridge.

| Param         | Type                                                              |
| ------------- | ----------------------------------------------------------------- |
| **`options`** | <code><a href="#automessageoptions">AutoMessageOptions</a></code> |

--------------------


### getPluginVersion()

```typescript
getPluginVersion() => Promise<PluginVersionResult>
```

Returns the platform implementation version marker.

**Returns:** <code>Promise&lt;<a href="#pluginversionresult">PluginVersionResult</a>&gt;</code>

--------------------


### addListener('connectionChanged', ...)

```typescript
addListener(eventName: 'connectionChanged', listenerFunc: (event: AutoConnectionChangedEvent) => void) => Promise<PluginListenerHandle>
```

Fired when the car host connects or disconnects.

| Param              | Type                                                                                                  |
| ------------------ | ----------------------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'connectionChanged'</code>                                                                      |
| **`listenerFunc`** | <code>(event: <a href="#autoconnectionchangedevent">AutoConnectionChangedEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('carAction', ...)

```typescript
addListener(eventName: 'carAction', listenerFunc: (event: AutoActionEvent) => void) => Promise<PluginListenerHandle>
```

Fired when the user selects an action row in the car UI.

| Param              | Type                                                                            |
| ------------------ | ------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'carAction'</code>                                                        |
| **`listenerFunc`** | <code>(event: <a href="#autoactionevent">AutoActionEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('messageReceived', ...)

```typescript
addListener(eventName: 'messageReceived', listenerFunc: (event: AutoMessageEvent) => void) => Promise<PluginListenerHandle>
```

Fired for application-defined native car bridge messages.

| Param              | Type                                                                              |
| ------------------ | --------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'messageReceived'</code>                                                    |
| **`listenerFunc`** | <code>(event: <a href="#automessageevent">AutoMessageEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### addListener('stateChanged', ...)

```typescript
addListener(eventName: 'stateChanged', listenerFunc: (event: AutoStateChangedEvent) => void) => Promise<PluginListenerHandle>
```

Fired when a persisted or transient state value changes.

| Param              | Type                                                                                        |
| ------------------ | ------------------------------------------------------------------------------------------- |
| **`eventName`**    | <code>'stateChanged'</code>                                                                 |
| **`listenerFunc`** | <code>(event: <a href="#autostatechangedevent">AutoStateChangedEvent</a>) =&gt; void</code> |

**Returns:** <code>Promise&lt;<a href="#pluginlistenerhandle">PluginListenerHandle</a>&gt;</code>

--------------------


### removeAllListeners()

```typescript
removeAllListeners() => Promise<void>
```

--------------------


### Interfaces


#### AutoAvailability

| Prop            | Type                                                  | Description                                                  |
| --------------- | ----------------------------------------------------- | ------------------------------------------------------------ |
| **`available`** | <code>boolean</code>                                  | Whether the current platform ships a native car integration. |
| **`connected`** | <code>boolean</code>                                  | Whether a car host is currently connected to this app.       |
| **`platform`**  | <code><a href="#autoplatform">AutoPlatform</a></code> | Platform that answered the request.                          |


#### AutoTemplateOptions

| Prop            | Type                               | Description                                 |
| --------------- | ---------------------------------- | ------------------------------------------- |
| **`title`**     | <code>string</code>                | Title shown at the top of the car template. |
| **`sections`**  | <code>AutoTemplateSection[]</code> | Sections and rows to show in the car UI.    |
| **`emptyText`** | <code>string</code>                | Text shown when there are no rows.          |


#### AutoTemplateSection

| Prop         | Type                            | Description                                                                             |
| ------------ | ------------------------------- | --------------------------------------------------------------------------------------- |
| **`header`** | <code>string</code>             | Optional section title. Supported by CarPlay; Android Auto currently flattens sections. |
| **`items`**  | <code>AutoTemplateItem[]</code> | Rows to render in this section.                                                         |


#### AutoTemplateItem

| Prop           | Type                                                | Description                                                                   | Default           |
| -------------- | --------------------------------------------------- | ----------------------------------------------------------------------------- | ----------------- |
| **`id`**       | <code>string</code>                                 | Stable action id sent back in the `carAction` event when the row is selected. |                   |
| **`title`**    | <code>string</code>                                 | Primary row text.                                                             |                   |
| **`subtitle`** | <code>string</code>                                 | Optional secondary row text.                                                  |                   |
| **`payload`**  | <code><a href="#autopayload">AutoPayload</a></code> | Optional value returned with the `carAction` event.                           |                   |
| **`enabled`**  | <code>boolean</code>                                | Whether the row can be selected.                                              | <code>true</code> |


#### AutoPayload


#### AutoStateOptions

| Prop        | Type                                                | Description                                       |
| ----------- | --------------------------------------------------- | ------------------------------------------------- |
| **`key`**   | <code>string</code>                                 | Application-defined state key.                    |
| **`value`** | <code><a href="#autopayload">AutoPayload</a></code> | JSON object to make available to native car code. |


#### AutoStateResult

| Prop        | Type                                                | Description                                                                  |
| ----------- | --------------------------------------------------- | ---------------------------------------------------------------------------- |
| **`key`**   | <code>string</code>                                 | Application-defined state key.                                               |
| **`value`** | <code><a href="#autopayload">AutoPayload</a></code> | Current JSON value for the requested key. Omitted when the key has no value. |


#### AutoStateKeyOptions

| Prop      | Type                | Description                    |
| --------- | ------------------- | ------------------------------ |
| **`key`** | <code>string</code> | Application-defined state key. |


#### AutoMessageOptions

| Prop          | Type                                                | Description                           |
| ------------- | --------------------------------------------------- | ------------------------------------- |
| **`type`**    | <code>string</code>                                 | Application-defined message type.     |
| **`payload`** | <code><a href="#autopayload">AutoPayload</a></code> | Optional application-defined payload. |


#### PluginVersionResult

| Prop          | Type                | Description                                                 |
| ------------- | ------------------- | ----------------------------------------------------------- |
| **`version`** | <code>string</code> | Version identifier returned by the platform implementation. |


#### PluginListenerHandle

| Prop         | Type                                      |
| ------------ | ----------------------------------------- |
| **`remove`** | <code>() =&gt; Promise&lt;void&gt;</code> |


#### AutoConnectionChangedEvent

| Prop            | Type                                                  |
| --------------- | ----------------------------------------------------- |
| **`connected`** | <code>boolean</code>                                  |
| **`platform`**  | <code><a href="#autoplatform">AutoPlatform</a></code> |


#### AutoActionEvent

| Prop           | Type                                                  |
| -------------- | ----------------------------------------------------- |
| **`id`**       | <code>string</code>                                   |
| **`title`**    | <code>string</code>                                   |
| **`payload`**  | <code><a href="#autopayload">AutoPayload</a></code>   |
| **`platform`** | <code><a href="#autoplatform">AutoPlatform</a></code> |


#### AutoMessageEvent

| Prop           | Type                                                  |
| -------------- | ----------------------------------------------------- |
| **`type`**     | <code>string</code>                                   |
| **`payload`**  | <code><a href="#autopayload">AutoPayload</a></code>   |
| **`platform`** | <code><a href="#autoplatform">AutoPlatform</a></code> |


#### AutoStateChangedEvent

| Prop            | Type                                                  | Description                                                                        |
| --------------- | ----------------------------------------------------- | ---------------------------------------------------------------------------------- |
| **`key`**       | <code>string</code>                                   | Application-defined state key.                                                     |
| **`value`**     | <code><a href="#autopayload">AutoPayload</a></code>   | Current JSON value for the updated key. Omitted when the key has no value.         |
| **`platform`**  | <code><a href="#autoplatform">AutoPlatform</a></code> | Platform that emitted the state update.                                            |
| **`transient`** | <code>boolean</code>                                  | Whether the update came from transient in-memory state instead of persisted state. |


### Type Aliases


#### AutoPlatform

<code>'ios' | 'android' | 'web'</code>

</docgen-api>
