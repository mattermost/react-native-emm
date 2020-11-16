import React, {
  createContext,
  useEffect,
  useState,
  FunctionComponent,
  useContext,
  ComponentType,
} from 'react';
import Emm from './emm';
import type { AuthenticateConfig } from './types/authenticate';
import type { ManagedConfig } from './types/managed';

const initialContext = {};
const Context = createContext<any>(initialContext);

export function useManagedConfig<T extends ManagedConfig>(): T {
  return useContext<T>(Context);
}

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

  return <Context.Provider value={managed}>{children}</Context.Provider>;
};

export type WithManagedConfigProps = {
  managedConfig: ManagedConfig;
};

export function withManagedConfig<T extends WithManagedConfigProps>(
  Component: ComponentType<T>
): ComponentType<T> {
  return function ManagedConfigComponent(props) {
    return (
      <Context.Consumer>
        {(managedConfig: ManagedConfig) => (
          <Component {...props} managedConfig={managedConfig} />
        )}
      </Context.Consumer>
    );
  };
}

export default Context;
