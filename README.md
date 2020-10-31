## @mattermost/react-native-emm

A React Native Module for EMM managed configurations

## Table of Contents

* [Installation](#installation)
  * [iOS](#ios-installation)
  * [Android](#android-installation)
* [Usage](#usage)

## Installation

Using npm:

```shell
npm install --save-exact @mattermost/react-native-emm
```

or using yarn:

```shell
yarn add -E @mattermost/react-native-emm
```

Then follow the instructions for your platform to link @mattermost/react-native-emm into your project:

### iOS installation
<details>
  <summary>iOS details</summary>

#### Standard Method

**React Native 0.60 and above**

Run `npx pod-install`. Linking is not required in React Native 0.60 and above.

**React Native 0.59 and below**

Run `react-native link @mattermost/react-native-emm` to link the react-native-emm library.

#### Using CocoaPods (required to enable caching)

Setup your Podfile like it is described in the [react-native documentation](https://facebook.github.io/react-native/docs/integration-with-existing-apps#configuring-cocoapods-dependencies). 

```diff
  pod 'Folly', :podspec => '../node_modules/react-native/third-party-podspecs/Folly.podspec'
+  `pod 'react-native-emm', :path => '../node_modules/@mattermost/react-native-emm/react-native-emm.podspec'`
end
```

</details>

### Android installation
<details>
  <summary>Android details</summary>

#### ** This library is only compatible with Android M (API level 23) or above"

**React Native 0.60 and above**
Linking is not required in React Native 0.60 and above.

**React Native 0.59 and below**
Run `react-native link @mattermost/react-native-emm` to link the react-native-emm library.

Or if you have trouble, make the following additions to the given files manually:

#### **android/settings.gradle**

```gradle
include ':mattermost.Emm'
project(':mattermost.Emm').projectDir = new File(rootProject.projectDir, '../node_modules/@mattermost/react-native-emm/android')
```

#### **android/app/build.gradle**

```diff
dependencies {
   ...
+   implementation project(':mattermost.Emm')
}
```

#### **android/gradle.properties**

```gradle.properties
android.useAndroidX=true
```

#### **MainApplication.java**

On top, where imports are:

```java
import com.mattermost.Emm.EmmPackage;
```

Add the `EmmPackage` class to your list of exported packages.

```diff
@Override
protected  List<ReactPackage> getPackages() {
  @SuppressWarnings("UnnecessaryLocalVariable")
  List<ReactPackage> packages = new  PackageList(this).getPackages();
  // Packages that cannot be autolinked yet can be added manually here, for ReactNativeEmmExample:
  // packages.add(new MyReactNativePackage());
+  packages.add(new EmmPackage());
  return packages;
}
```
**Configure your Android app to handle managed configurations**

Perform this steps manually as they are not handled by `Autolinking`.

#### **android/src/main/AndroidManifest.xml**

Enable `APP_RESTRICTIONS` in your Android manifest file

```diff
<application
  android:name=".MainApplication"
  android:label="@string/app_name"
  android:icon="@mipmap/ic_launcher"
  android:roundIcon="@mipmap/ic_launcher_round"
  android:allowBackup="false"
  android:theme="@style/AppTheme">
+  <meta-data  android:name="android.content.APP_RESTRICTIONS" android:resource="@xml/app_restrictions"  />
  <activity
    android:name=".MainActivity"
    ...
</application>
```

#### **android/src/main/res/xml/app_restriction.xml**

In this file you'll need to add **all** available managed configuration for the app ([see example](/example/android/src/main/res/xml/app_restriction.xml)). For more information check out [Android's guide: Set up managed configurations]([https://developer.android.com/work/managed-configurations](https://developer.android.com/work/managed-configurations))

```xml
<?xml version="1.0" encoding="utf-8"?>
<restrictions  xmlns:android="http://schemas.android.com/apk/res/android">
  <restriction
    android:key="YouManagedConfigKey"
    android:title="A title for your key"
    android:description="A description of what this key does"
    android:restrictionType="string"
    android:defaultValue="false"  />
</restrictions>
```
**Note:** In a production app, `android:title` and `android:description` should be drawn from a localized resource file.
</details>

## Usage

```javascript
// Load the module
import Emm from '@mattermost/react-native-emm';
```

### Events
* [addListener](#addlistener)

### Methods
* [authenticate](#authenticate)
* [deviceSecureWith](#devicesecurewith)
* [enableBlurScreen](#enableblurscreen)
* [exitApp](#exitapp)
* [getManagedConfig](#getmanagedconfig)
* [isDeviceSecured](#isdevicesecured)
* [openSecuritySettings](#opensecuritysettings)
* [setAppGroupId](#setappgroupid)

### Types
* [AuthenticateConfig](/types/authenticate.d.ts)
* [AuthenticationMethods](/types/authenticate.d.ts)
* [ManagedConfigCallBack](/types/events.d.ts)

#### addListener
`addListener(callback: ManagedConfigCallBack): EmitterSubscription;`

Event used to listen for Managed Configuration changes while the app is running.

Example:
```js
useEffect(() => {
  const  listener = Emm.addListener((config: AuthenticateConfig) => {
    setManaged(config);
  });

  return () => {
    listener.remove();
  };
});
```

**Note**: Don't forget to remove the listener when no longer needed to avoid memory leaks.

#### authenticate
`authenticate(opts: AuthenticateConfig): Promise<boolean>`

Request the user to authenticate using one of the device built-in authentication methods. You should call this after verifying that the [device is secure](#isdevicesecured)

Example:
```js
const opts: AuthenticateConfig = {
  reason: 'Some Reason',
  description: 'Some Description',
  fallback: true,
  supressEnterPassword: true,
};
const authenticated = await Emm.authenticate(opts);
```

Platforms: All

#### deviceSecureWith
`deviceSecureWith(): Promise<AuthenticationMethods>`

Get available device authentication methods.

Example:
```js
const optionsAvailable: AuthenticationMethods = await Emm.deviceSecureWith()
```

Platforms: All

#### enableBlurScreen
`enableBlurScreen(enabled: boolean): void`

iOS: Blurs the application screen in the App Switcher view
Android: Blanks the application screen in the Task Manager

Example:
```
Emm.enableBlurScreen(true);
```

Platforms: All

#### exitApp
`exitApp(): void`

Forces the app to exit. 

Example:
```
Emm.exitApp();
```
Platforms: All

#### getManagedConfig
`getManagedConfig(): Promise<Record<string, any>>`

Retrieves the Managed Configuration set by the Enterprise Mobility Management provider.

Notes:
Android uses the Restriction Manager to set the managed configuration settings and values while iOS uses NSUserDefaults under the key `com.apple.configuration.managed`

Example:
```
const manged: Record<string, any> = Emm.getManagedConfig(); // Managed configuration object containing keys and values
```

Platforms: all

##### isDeviceSecured
`isDeviceSecured(): Promise<boolean>`

Determines if the device has at least one authentication method enabled.

Example:
```
const secured = await Emm.isDeviceSecured();
```
Platforms: All

##### openSecuritySettings
`openSecuritySettings(): void`

If the device is not secured, you can use this function to take the user to the Device Security Settings to set up an authentication method.

Example:
```
Emm.openSecuritySettings();
```

**Note**: This function will close the running application.

Platforms: Android

##### setAppGroupId
`setAppGroupId(identifier: string): void`

At times you may built an iOS extension application (ex: Share Extension / Notification Extension), if you need access to the Managed Configuration you should set this value to your [App Group Identifier]([https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups)). This will create a copy of the managed configuration found in NSUserDefaults under the key `com.apple.configuration.managed` to a shared NSUserDefaults with your `App Group identifier` under the same key.

Example:
```
Emm.setAppGroupId('group.com.example.myapp);
```
Platforms: iOS


## TODOS

- [ ] Android: Use BiometricPrompt when available
---

**MIT Licensed**