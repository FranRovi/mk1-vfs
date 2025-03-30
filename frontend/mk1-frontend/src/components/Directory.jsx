import React from 'react';
// import Buttons from './Buttons'
import 'bootstrap-icons/font/bootstrap-icons.css';

function Directory (props) {
    return (
        <div className='container'>
            <div className="row">
                <div className="col-1">
                    <i class="bi bi-folder-fill"></i>
                    {/* <img height={30} width={30} alt="folder image" src="https://cdn.pixabay.com/photo/2013/07/12/19/27/folder-154803_960_720.png" /> */}
                </div>
                <div className="col">
                    {/* <i class="bi bi-folder"></i> */}
                    <h3>{props.name}</h3>
                </div>
                <div className="col-2">
                    {/* <input /> */}
                    <i class="bi bi-pencil-fill" onClick={() => console.log("pencil cliked")}> Update</i>
                    {/* <button className='btn btn-info'>update</button> */}
                </div>
                <div className="col-2">
                    <i class="bi bi-trash-fill" onClick={props.delDir}> Delete</i>
                    {/* <button className='btn btn-danger'>delete</button> */}
                </div>
            </div>
        </div>
    );
}

export default Directory;