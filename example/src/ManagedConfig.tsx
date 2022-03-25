import React, { useMemo } from 'react';
import { StyleSheet, Text, useColorScheme, View } from 'react-native';
import { Colors } from 'react-native/Libraries/NewAppScreen';

import { useManagedConfig } from '@mattermost/react-native-emm';

type ItemProps = {
  label: string;
  value: any;
};

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
  value: {
    fontSize: 16,
  },
});

const ConfigItem = ({ label, value }: ItemProps) => {
  const isDarkMode = useColorScheme() === 'dark';
  const color = isDarkMode ? Colors.white : Colors.black;
  return (
    <View style={styles.item}>
      <Text style={[styles.label, { color }]}>{label}</Text>
      <Text style={[styles.value, { color }]}>{value.toString()}</Text>
    </View>
  );
};

const ManagedConfig = () => {
  const managed = useManagedConfig<Record<string, any>>();
  const isDarkMode = useColorScheme() === 'dark';
  const color = isDarkMode ? Colors.white : Colors.black;

  const items = useMemo(() => {
    const keys = Object.keys(managed);

    if (keys.length) {
      return keys.map((key) => {
        return <ConfigItem key={key} label={`${key}:`} value={managed[key]} />;
      });
    }

    return <ConfigItem label={'No managed configuration set'} value={''} />;
  }, [managed]);

  return (
    <View style={styles.container}>
      <Text style={[styles.section, { color }]}>
        {'EMM Managed Configuration'}
      </Text>
      {items}
    </View>
  );
};

export default ManagedConfig;
