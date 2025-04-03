import React, { useState } from 'react';
import 'bootstrap-icons/font/bootstrap-icons.css';

function Directory (props) {
    const [newName, setNewName] = useState(props.name)
    const [isEdit, setIsEdit] = useState(false)

    const dataToSend = () => {
        props.delDir(props.id);
    }

    const dataToUpdate = () => {
        setIsEdit((prev) => !prev); 
    }

    const idToSend = () => {
        props.dirId(props.id, props.name);
    }

    const updateName = (e) => {
        setNewName((prev) => e.target.value);
    }

    const nameToBeUpdated = () => {
        setIsEdit((prev) => !prev); 
        props.updateDir(props.type, newName, props.id, props.parent_id);
    }

    return (
        <div className='container'>
            <div className="row">
                <div className="col-1">
                    <i className="bi bi-folder-fill"></i>
                </div>
                <div className="col">
                    <h5 className="" onClick={idToSend}>{props.name}</h5>
                    { isEdit && <div><input type="text" className="form-control mt-2 ms-2 ps-3" placeholder={newName} onChange={updateName} /><button className="btn btn-secondary mt-1 mb-3 p-2 btn-sm rounded-pill" onClick={nameToBeUpdated}>Confirm Change</button></div>}
                </div>
                <div className="col-1 d-flex">
                    <i className="bi bi-pencil-fill pe-2" id={props.id} onClick={dataToUpdate}></i>
                    <i className="bi bi-trash-fill ps-2" id={props.id} onClick={dataToSend}></i>
                </div>
            </div>
        </div>
    );
}

export default Directory;