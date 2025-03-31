import React, { useState } from 'react';
// import File from '../components/File'
import Directory from './components/Directory';
import { getDirectories, getFiles, getChildren, deleteDirectory, createDirectory } from "../src/services/frontend_services";

import 'bootstrap-icons/font/bootstrap-icons.css';
import './App.css'

function App() {
  const [type, setType] = useState("");
  const [name, setName] = useState("");
  const [parent_id, setParent_id] = useState("bec46267-cc3c-45bf-9bd2-52928c6f44ef");

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



  const [directoriesResults, setDirectoriesResults] = useState({"directories":[{"name":"Unavailable"}]})
    console.log("Directories when initializing the page: " + JSON.stringify(directoriesResults));

  // const [directoryResults, setDirectoryResults] = useState({"directories":[{"name":"Unavailable"}]})
  // console.log("Directories when initializing the page: " + JSON.stringify(directoriesResults));

  const [filesResult, setFilesResults] = useState({"directories":                [{"name":"Unavailable"}]})
    console.log("Files when initializing the page: " + JSON.stringify(filesResult));
  
  const [childrenResults, setChildrenResults] = useState({"directories":[]})
  console.log("Children when initializing the page: " + JSON.stringify(childrenResults));

  const directoriesClickHandler = async () => {
    const directoriesData = await getDirectories();
    console.log("Response from getDirectories function: " + JSON.stringify(directoriesData))
    setDirectoriesResults(directoriesData)
    const childrenData = await getChildren(parent_id);
    console.log("Response from getChildren function: " + JSON.stringify(childrenData.directories))
    setChildrenResults(childrenData.directories)

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

  const formSubmitHandler = async (e) => {
    e.preventDefault();
    console.log("submitFormHandler: " + name, type, parent_id);
    const createDir = await createDirectory(name, parent_id);
    console.log(createDir);
  }
  return (
    <>
      <h1>MK1 Virtual File System</h1>
      <h2>*** Front End ***</h2>
      <div>
        <h2 className="text-info">Directories</h2>
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
 
        {Object.keys(directoriesResults).length > 1 ? <Directory name={directoriesResults.directories[0].name} /> : <p></p>}
        {Object.keys(childrenResults).length > 1 ? childrenResults.map(result => <Directory key={result.id} id={result.id} name= {result.name} delDir= {deleteDirectoryClickHandler}/>) : <p>Nothing to show</p>}

        <br/>
        <button onClick={directoriesClickHandler}>Fetch Directories</button>
        <br/>
        <hr/>
        <h2 className="text-danger">Files</h2>
        {Object.keys(filesResult).length === 1 ? <p>No Files Available</p> : <p> Files Updated </p>}
        {JSON.stringify(filesResult.name)}
        <br/>
        <p></p>
        <button onClick={filesClickHandler}>Fetch Files</button>
        <br/>
        <hr/>
        <h2 className="text-warning">Create Documents</h2>
        <form onSubmit={formSubmitHandler} className="form-control">
          <div className="row">
            <div className='col-4'>
              <div className='form-check' onClick={updateType}>
                <input type='radio' name='doc_type' value='directory' id='dir' /> <label htmlFor="dir" >Directory</label>
              </div>
              <div className='form-check' onClick={updateType}>
                <input type='radio' name='doc_type' value='file' id='file' /> <label htmlFor="file">File</label>
              </div>
            </div>
            <div className='col-4'>
              <div class="input-group mb-3">
                {/* <span class="input-group-text" id="basic-addon1">@</span> */}
                <input type="text" class="form-control" placeholder="Name of document" aria-label="Username" aria-describedby="basic-addon1" onChange={updateName} />
              </div>
            </div>
            <div className='col-4'>
              <button type='submit' className='btn btn-primary'>Submit</button>
            </div>
            {<pre>{type}{name}</pre>}
          </div>
        
        </form>
      </div>

    </>
  )
}

export default App
