import React, {
  createContext,
  useEffect,
  useState,
  FunctionComponent,
} from 'react';
import Emm from '@mattermost/react-native-emm';

const initialContext = {};
const EMMContext = createContext<Record<string, any>>(initialContext);

export const Provider: FunctionComponent = ({ children }) => {
  const [managed, setManaged] = useState<Record<string, any>>(initialContext);

  useEffect(() => {
    Emm.getManagedConfig().then((config: AuthenticateConfig) => {
      setManaged(config);
    });
  }, []);

  useEffect(() => {
    const listener = Emm.addListener((config: AuthenticateConfig) => {
      setManaged(config);
    });

    return () => {
      listener.remove();
    };
  });

  return <EMMContext.Provider value={managed}>{children}</EMMContext.Provider>;
};

export default EMMContext;
