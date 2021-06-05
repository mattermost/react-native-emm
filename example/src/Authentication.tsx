import React, { useMemo, useState } from 'react';
import { Alert, StyleSheet, Text, useColorScheme, View } from 'react-native';
import { Colors } from 'react-native/Libraries/NewAppScreen';

import Emm from '@mattermost/react-native-emm';
import type { AuthenticateConfig } from '@mattermost/react-native-emm';

import Button from './Button';

type AuthItemProps = {
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

const AuthItem = ({ label, value }: AuthItemProps) => {
  const isDarkMode = useColorScheme() === 'dark';
  const color = isDarkMode ? Colors.white : Colors.black;
  return (
    <View style={styles.item}>
      <Text style={[styles.label, { color }]}>{`${label}:`}</Text>
      <Text style={[styles.value, { color }]}>{value.toString()}</Text>
    </View>
  );
};

const Authentication = () => {
  const [methods, setMethods] = useState<Record<string, any>>({});
  const [auth, setAuth] = useState<boolean | undefined>(undefined);
  const isDarkMode = useColorScheme() === 'dark';
  const color = isDarkMode ? Colors.white : Colors.black;

  const authenticate = async () => {
    const secured = await Emm.isDeviceSecured();

    if (secured) {
      const opts: AuthenticateConfig = {
        reason: 'Some Reason',
        description: 'Test description',
        fallback: true,
        supressEnterPassword: false,
      };
      const authenticated = await Emm.authenticate(opts);
      setAuth(authenticated);
    } else {
      Alert.alert(
        'Authentication Error',
        'There are no authentication methods availble i this device'
      );
    }
  };

  React.useEffect(() => {
    Emm.deviceSecureWith().then(setMethods);
  }, []);

  const items = useMemo(() => {
    return Object.keys(methods).map((key) => {
      return <AuthItem key={key} label={key} value={methods[key]} />;
    });
  }, [methods]);

  return (
    <View style={styles.container}>
      <Text style={[styles.section, { color }]}>
        {'Device Authentication Methods'}
      </Text>
      {items}
      <Button onPress={authenticate} success={auth}>
        <Text style={{ color }}>{'Authenticate'}</Text>
      </Button>
    </View>
  );
};

export default Authentication;
