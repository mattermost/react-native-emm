import * as React from 'react';
import { StyleSheet, View, Text } from 'react-native';
import RNEmm from '@mattermost/react-native-emm';

export default function App() {
  const [result, setResult] = React.useState<any | undefined>();

  const exitApp = () => {
    RNEmm.exitApp();
  };

  React.useEffect(() => {
    RNEmm.deviceSecureWith().then(setResult);
    RNEmm.enableBlurScreen(true);
    RNEmm.isDeviceSecured().then((secured) => {
      if (secured) {
        RNEmm.authenticate('Some reason').then((authenticated: boolean) => {
          console.log('Authenticated?', authenticated);
          if (authenticated) {
            RNEmm.getManagedConfig().then((config) => {
              console.log('GOT MANAGED CONFIG', config);
            });
          }
        });
      }
    });
  }, []);

  React.useEffect(() => {
    const listener = RNEmm.addListener((config: any) => {
      console.log('GOT MANAGED CONFIG EVENT', config);
    });

    return () => {
      listener.remove();
    };
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.label} onPress={exitApp}>
        Result: {JSON.stringify(result)}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  label: {
    fontSize: 18,
  },
});
