import React, { useState } from 'react';
import { Platform, StyleSheet, Text, useColorScheme, View } from 'react-native';
import { Colors } from 'react-native/Libraries/NewAppScreen';

import Emm from '@mattermost/react-native-emm';

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
  const isDarkMode = useColorScheme() === 'dark';
  const color = isDarkMode ? Colors.white : Colors.black;

  const toggle = () => {
    Emm.enableBlurScreen(!enabled);
    setEnabled(!enabled);
  };

  return (
    <Button onPress={toggle} success={enabled}>
      <Text style={{ color }}>{'Blur application screen'}</Text>
    </Button>
  );
};

const ExitApp = () => {
  const isDarkMode = useColorScheme() === 'dark';
  const color = isDarkMode ? Colors.white : Colors.black;
  const exitApp = () => {
    Emm.exitApp();
  };

  return (
    <>
      <View style={styles.separator} />
      <Button onPress={exitApp}>
        <Text style={{ color }}>{'Exit app'}</Text>
      </Button>
    </>
  );
};

const SecuritySettings = () => {
  const isDarkMode = useColorScheme() === 'dark';
  const color = isDarkMode ? Colors.white : Colors.black;

  const settings = () => {
    Emm.openSecuritySettings();
  };

  if (Platform.OS !== 'android') {
    return null;
  }

  return (
    <>
      <View style={styles.separator} />
      <Button onPress={settings}>
        <Text style={{ color }}>{'Open Security Settings'}</Text>
      </Button>
    </>
  );
};

const Authentication = () => {
  const isDarkMode = useColorScheme() === 'dark';
  const color = isDarkMode ? Colors.white : Colors.black;
  return (
    <View style={styles.container}>
      <Text style={[styles.section, { color }]}>{'Other Options'}</Text>
      <BlurAppScreen />
      <SecuritySettings />
      <ExitApp />
    </View>
  );
};

export default Authentication;
