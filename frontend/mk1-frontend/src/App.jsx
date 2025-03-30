import React, { useState } from 'react';
// import File from '../components/File'
import Directory from './components/Directory';
import { getDirectories, getFiles, getChildren, deleteDirectory } from "../src/services/frontend_services";

import 'bootstrap-icons/font/bootstrap-icons.css';
import './App.css'

function App() {
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
    const childrenData = await getChildren("bec46267-cc3c-45bf-9bd2-52928c6f44ef");
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

  return (
    <>
      <h1>MK1 Virtual File System *** Front End</h1>
      <div>
        <h1 className="text-info">Directories</h1>
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
        {/* {Object.keys(directoriesResults).length === 1 ? <p>No Directories Available</p> : <p> Directories Updated </p>} */}
        {/* {Object.keys(directoriesResults).length > 1 ? <p>{JSON.stringify(directoriesResults.directories[0].name)}</p> : <p></p>} */}
        {Object.keys(directoriesResults).length > 1 ? <Directory name={directoriesResults.directories[0].name} /> : <p></p>}
        {Object.keys(childrenResults).length > 1 ? childrenResults.map(result => <Directory key={result.id} id={result.id} name= {result.name} delDir= {deleteDirectoryClickHandler}/>) : <p>Nothing to show</p>}
        {/* // {JSON.stringify(directoriesResults.directories[0].name)} : <p></p> */}
        {/* <Directory name={directoriesResults.directories[0].name}/> */}
        {/* {JSON.stringify(directoriesResults.directories[0].name)} */}
        <br/>
        <button onClick={directoriesClickHandler}>Fetch Directories</button>
        <br/>
        <hr/>
        <h1 className="text-danger">Files</h1>
        {Object.keys(filesResult).length === 1 ? <p>No Files Available</p> : <p> Files Updated </p>}
        {/* {Object.keys(filesResult).length > 1 ? <p>{JSON.stringify(filesResult.directories[0].name)}</p> : <p></p>} */}
        {JSON.stringify(filesResult.name)}
        <br/>
        <p></p>
        <button onClick={filesClickHandler}>Fetch Files</button>
        <br/>
        <hr/>
        <h1 className="text-warning">Create Documents</h1>
      </div>

    </>
  )
}

export default App
