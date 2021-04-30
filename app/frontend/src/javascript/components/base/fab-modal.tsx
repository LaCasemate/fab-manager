import React, { ReactNode, BaseSyntheticEvent } from 'react';
import Modal from 'react-modal';
import { useTranslation } from 'react-i18next';
import { Loader } from './loader';
import CustomAssetAPI from '../../api/custom-asset';
import { CustomAssetName } from '../../models/custom-asset';
import { FabButton } from './fab-button';

Modal.setAppElement('body');

export enum ModalSize {
  small = 'sm',
  medium = 'md',
  large = 'lg'
}

interface FabModalProps {
  title: string,
  isOpen: boolean,
  toggleModal: () => void,
  confirmButton?: ReactNode,
  closeButton?: boolean,
  className?: string,
  width?: ModalSize,
  customFooter?: ReactNode,
  onConfirm?: (event: BaseSyntheticEvent) => void,
  preventConfirm?: boolean
}

// initial request to the API
const blackLogoFile = CustomAssetAPI.get(CustomAssetName.LogoBlackFile);

/**
 * This component is a template for a modal dialog that wraps the application style
 */
export const FabModal: React.FC<FabModalProps> = ({ title, isOpen, toggleModal, children, confirmButton, className, width = 'sm', closeButton, customFooter, onConfirm, preventConfirm }) => {
  const { t } = useTranslation('shared');

  // the theme's logo, for back backgrounds
  const blackLogo = blackLogoFile.read();

  /**
   * Check if the confirm button should be present
   */
  const hasConfirmButton = (): boolean => {
    return confirmButton !== undefined;
  }

  /**
   * Should we display the close button?
   */
  const hasCloseButton = (): boolean => {
    return closeButton;
  }

  /**
   * Check if there's a custom footer
   */
  const hasCustomFooter = (): boolean => {
    return customFooter !== undefined;
  }

  return (
    <Modal isOpen={isOpen}
           className={`fab-modal fab-modal-${width} ${className}`}
           overlayClassName="fab-modal-overlay"
           onRequestClose={toggleModal}>
      <div className="fab-modal-header">
        <Loader>
          <img src={blackLogo.custom_asset_file_attributes.attachment_url}
               alt={blackLogo.custom_asset_file_attributes.attachment}
               className="modal-logo" />
        </Loader>
        <h1>{ title }</h1>
      </div>
      <div className="fab-modal-content">
        {children}
      </div>
      <div className="fab-modal-footer">
        <Loader>
          {hasCloseButton() &&<FabButton className="modal-btn--close" onClick={toggleModal}>{t('app.shared.buttons.close')}</FabButton>}
          {hasConfirmButton() && <FabButton className="modal-btn--confirm" disabled={preventConfirm} onClick={onConfirm}>{confirmButton}</FabButton>}
          {hasCustomFooter() && customFooter}
        </Loader>
      </div>
    </Modal>
  );
}

