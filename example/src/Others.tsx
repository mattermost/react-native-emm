import React, { useState } from 'react';
import { Platform, StyleSheet, Text, View } from 'react-native';
import RNEmm from '@mattermost/react-native-emm';

import Button from './Button';

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 12,
    width: '100%',
  },
  item: {
    flexDirection: 'row',
    marginBottom: 2,
  },
  label: {
    fontSize: 16,
    fontWeight: 'bold',
    marginRight: 5,
  },
  section: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 5,
  },
  separator: {
    marginVertical: 2.5,
  },
  value: {
    fontSize: 16,
  },
});

const BlurAppScreen = () => {
  const [enabled, setEnabled] = useState<boolean | undefined>(undefined);

  const toggle = () => {
    RNEmm.enableBlurScreen(!enabled);
    setEnabled(!enabled);
  };

  return (
    <Button onPress={toggle} success={enabled}>
      <Text>{'Blur application screen'}</Text>
    </Button>
  );
};

const ExitApp = () => {
  const exitApp = () => {
    RNEmm.exitApp();
  };

  return (
    <>
      <View style={styles.separator} />
      <Button onPress={exitApp}>
        <Text>{'Exit app'}</Text>
      </Button>
    </>
  );
};

const SecuritySettings = () => {
  const settings = () => {
    RNEmm.openSecuritySettings();
  };

  if (Platform.OS !== 'android') {
    return null;
  }

  return (
    <>
      <View style={styles.separator} />
      <Button onPress={settings}>
        <Text>{'Open Security Settings'}</Text>
      </Button>
    </>
  );
};

const Authentication = () => {
  return (
    <View style={styles.container}>
      <Text style={styles.section}>{'Other Options'}</Text>
      <BlurAppScreen />
      <SecuritySettings />
      <ExitApp />
    </View>
  );
};

export default Authentication;
