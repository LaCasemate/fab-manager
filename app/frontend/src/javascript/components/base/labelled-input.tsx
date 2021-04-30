import React from 'react';

interface LabelledInputProps {
  id: string,
  type: string,
  label: string,
  value: any,
  onChange: (value: any) => void
}

/**
 * This component shows input field with its label, styled
 */
export const LabelledInput: React.FC<LabelledInputProps> = ({ id, type, label, value, onChange }) => {
  return (
    <div className="input-with-label">
      <label className="label" htmlFor={id}>{label}</label>
      <input className="input" id={id} type={type} value={value} onChange={onChange} />
    </div>
  );
}
