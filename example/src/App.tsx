import * as React from 'react';
import { SafeAreaView, ScrollView, StyleSheet, View } from 'react-native';
import { Provider } from '@mattermost/react-native-emm';

import Authentication from './Authentication';
import ManagedConfig from './ManagedConfig';
import Others from './Others';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
  },
  divider: {
    width: '100%',
    height: 1,
    backgroundColor: 'lightgray',
    marginVertical: 10,
  },
});

const Divider = () => {
  return <View style={styles.divider} />;
};

export default function App() {
  return (
    <Provider>
      <SafeAreaView style={styles.container}>
        <ScrollView>
          <ManagedConfig />
          <Divider />
          <Authentication />
          <Divider />
          <Others />
        </ScrollView>
      </SafeAreaView>
    </Provider>
  );
}
