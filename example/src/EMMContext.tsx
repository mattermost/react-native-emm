import React, {
  createContext,
  useEffect,
  useState,
  FunctionComponent,
} from 'react';
import RNEmm from '@mattermost/react-native-emm';

const initialContext = {};
const EMMContext = createContext<Record<string, any>>(initialContext);

export const Provider: FunctionComponent = ({ children }) => {
  const [managed, setManaged] = useState<Record<string, any>>(initialContext);

  useEffect(() => {
    RNEmm.getManagedConfig().then((config: AuthenticateConfig) => {
      setManaged(config);
    });
  }, []);

  useEffect(() => {
    const listener = RNEmm.addListener((config: AuthenticateConfig) => {
      setManaged(config);
    });

    return () => {
      listener.remove();
    };
  });

  return <EMMContext.Provider value={managed}>{children}</EMMContext.Provider>;
};

export default EMMContext;
