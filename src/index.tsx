import { NativeModules } from 'react-native';

type ReactNativeEmmType = {
  multiply(a: number, b: number): Promise<number>;
};

const { ReactNativeEmm } = NativeModules;

export default ReactNativeEmm as ReactNativeEmmType;
