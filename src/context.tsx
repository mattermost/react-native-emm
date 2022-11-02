import React, {
  createContext,
  useEffect,
  useState,
  useContext,
  ComponentType,
} from 'react';
import Emm from './emm';

interface Props {
  children: React.ReactNode;
}

const initialContext = Emm.getManagedConfig<unknown>();
const Context = createContext<any>(initialContext);

export function useManagedConfig<T>(): T {
  return useContext<T>(Context);
}

export const Provider = ({ children }: Props) => {
  const [managed, setManaged] = useState<unknown>(Emm.getManagedConfig());

  useEffect(() => {
    const listener = Emm.addListener((config: unknown) => {
      setManaged(config);
    });

    return () => {
      listener.remove();
    };
  });

  return <Context.Provider value={managed}>{children}</Context.Provider>;
};

export function withManagedConfig<T, P extends JSX.IntrinsicAttributes = {}>(
  Component: ComponentType<P & { managedConfig: T }>
): ComponentType<P> {
  return function ManagedConfigComponent(props: P) {
    return (
      <Context.Consumer>
        {(managedConfig: T) => (
          <Component {...props} managedConfig={managedConfig} />
        )}
      </Context.Consumer>
    );
  };
}

export default Context;
