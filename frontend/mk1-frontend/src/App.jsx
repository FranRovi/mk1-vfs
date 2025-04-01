import React, { useState, useEffect } from 'react';
import File from './components/File'
import Directory from './components/Directory';
import { deleteDirectory, createDocument, getDocuments } from "../src/services/frontend_services";

import 'bootstrap-icons/font/bootstrap-icons.css';
import './App.css'

function App() {
  const [type, setType] = useState("");
  const [name, setName] = useState("");
  const [parent_id, setParent_id] = useState("bec46267-cc3c-45bf-9bd2-52928c6f44ef") // Desktop ID
  // ("66102b24-60ef-4a7c-bce1-1b2e6d071811");
  // 2165252f-7fbe-4299-afc3-d1dc35e5937a Work ID

  const [documents, setDocuments] = useState({directories:[],files:[]});

  // useEffect(() => {
  //   setDocuments(getDirectories)
  // }, [documents])

  // console.log(documents)

  const updateName = (e) => {
    setName((prev) => e.target.value);
    console.log("Updated name: " + name);
  }

  const updateType = (e) => {
    setType((prev) => e.target.value);
    console.log("Updated radio button: " + type);
    
    // setType();
  }
  // const formChangeHandler = (e) => {
  //   setFormData({
  //     ...formData,
  //     [e.target.name] : e.target.value,
  //   });
  // };

  // const formSubmitHandler = (e) => {
  //   e.preventDefault();
  //   'bec46267-cc3c-45bf-9bd2-52928c6f44ef'

  // }


  const documentsClickHandler = async () => {
    const documentsData = await getDocuments();
    console.log("Response from getDocuments function: " + JSON.stringify(documentsData));
    setDocuments(documentsData);
    console.log(documentsData);
  }

  const filesClickHandler = async () => {
    const filesData = await getFiles();
    console.log("Response from getFiles function: " + JSON.stringify(filesData))
    setFilesResults(filesData)
  }

  const deleteDirectoryClickHandler = async (dir_id) => {
    const deleteDir = await deleteDirectory(dir_id);
    console.log("Directory Deleted: " + deleteDir);
  }

  // const formSubmitHandler = async (e) => {
  //   e.preventDefault();
  //   console.log("submitFormHandler: " + name, type, parent_id);
  //   const createDir = await createDirectory(name, parent_id);
  //   console.log(createDir);
  // }

  const formSubmitHandler = async (e) => {
    e.preventDefault();
    console.log("submitFormHandler: " + type, name, parent_id);
    const createDoc = await createDocument(type, name, parent_id);
    console.log(createDoc);
  }
  return (
    <>
      <h1>MK1 Virtual File System</h1>
      <h2>*** Front End ***</h2>
      <div>
        <div className='row'>
          <div className='col-6'><h2 className="text-info">Directories</h2>
        {/* <div className="table-responsive"> 
          <table className="table">
            <tbody>
              <tr>
                {directoriesResults && directoriesResults.map((directory)=> (<td>
                  {/* <h2>{directory.name}</h2> 
                  <File name={name} />
                  </td>)) }
              </tr>
            </tbody>
          </table>
        </div> */}
 
        {Object.keys(documents.directories).length > 1 ? documents.directories.map(result => <Directory key={result.id} id={result.id} name= {result.name} delDir= {deleteDirectoryClickHandler}/>) : <p>Nothing to show</p>}

        <br/>
        <br/>
        </div>
          <div className='col 7-12'>
            <h2 className="text-danger">Files</h2>
            {Object.keys(documents.files).length > 1 ? documents.files.map(result => <File key={result.id} id={result.id} name= {result.name} delDir= {deleteDirectoryClickHandler}/>) : <p>Nothing to show</p>}
        <br/>
        <p></p>
      
        <br/>

          </div> 
        </div>
        <hr/>
        <button className='btn btn-primary text-center' onClick={documentsClickHandler}>Fetch Documents</button>
        
        <h2 className="text-warning">Create Documents</h2>
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
                {/* <span class="input-group-text" id="basic-addon1">@</span> */}
                <input type="text" className="form-control mt-2" placeholder="Name of document" aria-label="Username" aria-describedby="basic-addon1" onChange={updateName} />
              </div>
            </div>
            <div className='col-4'>
              <button type='submit' className='btn btn-primary mt-2'>Submit</button>
            </div>
            {<pre>{type} <span>   </span> {name}</pre>}
          </div>
        </form>
      </div>
    </>
  )
}

export default App
