import React, { useState } from 'react';
import 'bootstrap-icons/font/bootstrap-icons.css';

function Directory (props) {
    const [newName, setNewName] = useState(props.name)
    const [isEdit, setIsEdit] = useState(false)

    const dataToSend = () => {
        console.log("Garbage Icon cliked");
        props.delDir(props.id);
    }

    const dataToUpdate = () => {
        // console.log("Garbage Icon cliked");
        () => console.log("pencil cliked: " + props.id)
        // props.delDir(props.id);
        setIsEdit((prev) => !prev); 
    }

    const idToSend = () => {
        props.dirId(props.id);
        console.log("Name cliked")
        setIsEdit((prev) => !prev); 
    }

    const updateName = (e) => {
        setNewName((prev) => e.target.value);
        console.log("Updated name: " + newName);
        console.log(newName)
    }

    const nameToBeUpdated = () => {
        console.log("Name To Be Updated: " + newName)
        setIsEdit((prev) => !prev); 
        props.updateDir(props.type, newName, props.id, props.parent_id);
    }

    // updateFormHandler = async (e) => {
    //     e.preventDefault();
    //     props.updateDir(newName);
    //     const updateDoc
    // }

    return (
        <div className='container'>
            <div className="row">
                <div className="col-1">
                    <i class="bi bi-folder-fill"></i>
                    {/* <img height={30} width={30} alt="folder image" src="https://cdn.pixabay.com/photo/2013/07/12/19/27/folder-154803_960_720.png" /> */}
                </div>
                <div className="col">
                    {/* <i class="bi bi-folder"></i> */}
                    <h5 className="" onClick={idToSend}>{props.name}</h5>
                    { isEdit && <div><input type="text" className="form-control mt-2 ms-2 ps-3" placeholder={newName} onChange={updateName} /><button className="btn btn-secondary mt-1 mb-3 p-2" onClick={nameToBeUpdated}>Confirm Change</button></div>}
                </div>
                <div className="col-1 d-flex">
                    <i class="bi bi-pencil-fill pe-2" id={props.id} onClick={dataToUpdate}></i>
                    <i class="bi bi-trash-fill ps-2" id={props.id} onClick={dataToSend}></i>
                </div>
            </div>
        </div>
    );
}

export default Directory;