import React from 'react';
import Buttons from './Buttons'

const File = (props) => {
    return(
        <div className='row'>
            <h2>{props.name}</h2>
            <Buttons />
        </div>
    );
};

export default File;