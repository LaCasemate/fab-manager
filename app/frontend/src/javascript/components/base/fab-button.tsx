import React, { ReactNode, BaseSyntheticEvent } from 'react';

interface FabButtonProps {
  onClick?: (event: BaseSyntheticEvent) => void,
  icon?: ReactNode,
  className?: string,
  disabled?: boolean,
  type?: 'submit' | 'reset' | 'button',
  form?: string,
}

/**
 * This component is a template for a clickable button that wraps the application style
 */
export const FabButton: React.FC<FabButtonProps> = ({ onClick, icon, className, disabled, type, form, children }) => {
  /**
   * Check if the current component was provided an icon to display
   */
  const hasIcon = (): boolean => {
    return !!icon;
  }

  /**
   * Handle the action of the button
   */
  const handleClick = (e: BaseSyntheticEvent): void => {
    if (typeof onClick === 'function') {
      onClick(e);
    }
  }

  return (
    <button type={type} form={form} onClick={handleClick} disabled={disabled} className={`fab-button ${className ? className : ''}`}>
      {hasIcon() && <span className="fab-button--icon">{icon}</span>}
      {children}
    </button>
  );
}

FabButton.defaultProps = { type: 'button' };

