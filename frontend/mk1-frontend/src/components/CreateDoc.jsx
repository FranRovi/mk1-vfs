import React, {useState} from 'react';
import { createDocument } from "../services/frontend_services";

const CreateDoc = (props) => {

    const updateName = (e) => {
        const [type, setType] = useState("");
        const [name, setName] = useState("");

        setName((prev) => e.target.value);
        console.log("Updated name: " + name);
    }
    
    const updateType = (e) => {
    setType((prev) => e.target.value);
    console.log("Updated radio button: " + type);
    
    // setType();
    }
    const formSubmitHandler = async (e) => {
        e.preventDefault();
        console.log("submitFormHandler: " + type, name, parent_id);
        const createDoc = await createDocument(type, name, parent_id);
        console.log(createDoc);
    }

    return(<>
        <h1></h1>
        <table className="table">
            <thead>
                <tr>
                    <th scope="col">Create Documents</th>
                    <th scope="col"></th>
                    {/* <th scope="col"></th>
                    <th scope="col"></th> */}
                    {/*<th scope="col"></th> */}
                </tr>
            </thead>
            <tbody>
                <tr>
                    <th scope="row"></th>
                        <td colSpan="4">
                            <form onSubmit={formSubmitHandler} className="form-control">
                                <div className="row">
                                    <div className='col-4 mt-2'>
                                        <div className='form-check' onClick={updateType}>
                                            <input type='radio' name='doc_type' value='directory' id='dir' /> <label htmlFor="dir" >Directory</label>
                                        </div>
                                        <div className='form-check' onClick={updateType}>
                                            <input type='radio' name='doc_type' value='file' id='file' /> <label htmlFor="file">File</label>
                                        </div>
                                    </div>
                                    <div className='col-4'>
                                        <div className="input-group mb-3">
                                            <input type="text" className="form-control mt-2" placeholder="Name of document" onChange={updateName} />
                                        </div>
                                    </div>
                                    <div className='col-4'>
                                        <button type='submit' className='btn btn-primary mt-2'>Submit</button>
                                    </div>
                                </div>
                                
                            </form>
                        </td>
                </tr>
                        {/* <td>HOLA</td> */}
                        {/* <form onSubmit={formSubmitHandler} className="form-control">
                            <div className="row">
                                <div className='col-4 mt-2'>
                                <div className='form-check' onClick={updateType}>
                                    <input type='radio' name='doc_type' value='directory' id='dir' /> <label htmlFor="dir" >Directory</label>
                                </div>
                                <div className='form-check' onClick={updateType}>
                                    <input type='radio' name='doc_type' value='file' id='file' /> <label htmlFor="file">File</label>
                                </div>
                                </div>
                                <div className='col-4'>
                                <div className="input-group mb-3">
                                    <input type="text" className="form-control mt-2" placeholder="Name of document" onChange={updateName} />
                                </div>
                                </div>
                                <div className='col-4'>
                                <button type='submit' className='btn btn-primary mt-2'>Submit</button>
                                </div>
                                {<pre>{type} <span>   </span> {name}</pre>}
                            </div>
                        </form>  */}
                    
                
            </tbody>
        </table>
    </>)
}

export default CreateDoc;