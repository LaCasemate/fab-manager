import React, { Suspense } from 'react';

/**
 * This component is a wrapper that display a loader while the children components have their rendering suspended
 */
export const Loader: React.FC = ({children }) => {
  const loading = (
    <div className="fa-3x">
      <i className="fas fa-circle-notch fa-spin" />
    </div>
  );
  return (
    <Suspense fallback={loading}>
        {children}
    </Suspense>
  );
}

