import React from 'react';
import Buttons from './Buttons'
import 'bootstrap-icons/font/bootstrap-icons.css';

const File = (props) => {
    const dataToSend = () => {
        props.delFile(props.id);
    }
    
    return(
        // <div className='row'>
        //     <h2>{props.name}</h2>
        //     <Buttons />
        // </div>
        <div className='container'>
            <div className="row">
                <div className="col-1">
                    <i class="bi bi-file-earmark-text"></i>
                    {/* <img height={30} width={30} alt="folder image" src="https://cdn.pixabay.com/photo/2013/07/12/19/27/folder-154803_960_720.png" /> */}
                </div>
                <div className="col">
                    {/* <i class="bi bi-folder"></i> */}
                    <h5 className="">{props.name}</h5>
                </div>
                <div className="col-1 d-flex">
                    <i class="bi bi-pencil-fill pe-2" id={props.id} onClick={() => console.log("pencil cliked: " + props.id)}></i>
                    <i class="bi bi-trash-fill ps-2" id={props.id} onClick={dataToSend}></i>
                </div>
            </div>
        </div>
    );
};

export default File;