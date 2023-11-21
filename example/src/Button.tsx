import React, { type FunctionComponent } from 'react';
import {
  Pressable,
  type PressableProps,
  type PressableStateCallbackType,
  type StyleProp,
  StyleSheet,
  type ViewStyle,
} from 'react-native';

const ripple = {
  color: 'gray',
  borderless: false,
};

const styles = StyleSheet.create({
  button: {
    borderRadius: 8,
    padding: 6,
    height: 40,
    flexShrink: 1,
    borderColor: 'lightgray',
    borderWidth: 1,
    alignItems: 'center',
    justifyContent: 'center',
  },
  success: {
    backgroundColor: 'lightgreen',
  },
  failed: {
    backgroundColor: 'red',
  },
});

interface ButtonProps extends PressableProps {
  style?: ViewStyle;
  success?: boolean | undefined;
}

const Button: FunctionComponent<ButtonProps> = (props) => {
  let successStyle: ViewStyle;
  if (typeof props.success === 'boolean') {
    successStyle = props.success ? styles.success : styles.failed;
  }

  const pressedStyle = ({
    pressed,
  }: PressableStateCallbackType): StyleProp<ViewStyle> => [
    {
      backgroundColor: pressed ? 'rgba(0, 0, 0, 0.2)' : undefined,
    },
    styles.button,
    successStyle,
    props.style,
  ];

  return (
    <Pressable
      style={pressedStyle}
      onPress={props.onPress}
      android_ripple={ripple}
    >
      {props.children}
    </Pressable>
  );
};

export default Button;
