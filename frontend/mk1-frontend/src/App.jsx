import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import File from './components/File'
import Directory from './components/Directory';
import { deleteDirectory, createDocument, getDocuments, deleteFile, updateDocument, getRoot } from "../src/services/frontend_services";

import 'bootstrap-icons/font/bootstrap-icons.css';
import './App.css'

function App() {
  const [type, setType] = useState("directory");
  const [name, setName] = useState("");
  const [parent_id, setParent_id] = useState(null);
  // ("66102b24-60ef-4a7c-bce1-1b2e6d071811") // Desktop ID;
  // 2165252f-7fbe-4299-afc3-d1dc35e5937a Work ID
  // const [isEdit, setIsEdit] = useState(true)
  // const [updatedName, setUpdatedName] = useState();

  const [documents, setDocuments] = useState({directories:[],files:[]});
  const [currentDirId, setCurrentDirId] = useState([])
  const [path, setPath] = useState([])


  const findRoot = async () => {
    const response = await getRoot()
    // console.log(JSON.stringify(response))
    setDocuments(response)
    // console.log(documents)
  }
  
  useEffect(() => {
    findRoot()
    // path.push("Root")
    // const response = getRoot()
    // console.log(JSON.stringify(response))
    // setTestDirFetch(response)
    // setDocuments(getDirectories)
  }, [])
  // console.log(JSON.stringify(testDirFetch))

  // console.log(documents)

  const updateName = (e) => {
    setName((prev) => e.target.value);
    console.log("Updated name: " + name);
  }

  const updateType = (e) => {
    // setType(() => e.target.value);
    // console.log("Updated radio button: " + type);

    console.log("Prev radio Button Value: " + type)
    if (e.target.value === 'directory' && type !== 'directory'
    ) {
      setType(() => 'directory')
    }

    if (e.target.value === 'file' && type !== 'file'
    ) {
      setType(() => 'file')
    }
    console.log("Updated radio button: " + type)

    
    // setType();
  }
  const goBackDir = async () => {
    // console.log("current path: " + path)
    path.pop()
    // console.log("current path: " + path)
    setPath(path);
    // console.log("current dir ids: " + currentDirId)
    currentDirId.pop();
    setCurrentDirId(currentDirId);
    setParent_id(currentDirId[currentDirId.length - 1])
    // console.log("current dir ids: " + currentDirId)
    if (currentDirId.length === 0) {
      setParent_id(null);
      const response = await getRoot()
      setDocuments(response)
    } else {
      let dir_id = currentDirId[currentDirId.length - 1];
      // console.log("dir_id: " + dir_id)
      setParent_id(dir_id);
      const documentsData = await getDocuments(dir_id);
      setDocuments(documentsData);  
    }
  }

  const documentsClickHandler = async (dir_id, dir_name) => {
    const documentsData = await getDocuments(dir_id);
    console.log("Response from getDocuments function: " + JSON.stringify(documentsData));
    setDocuments(documentsData);
    path.push(dir_name);
    setPath(path);
    console.log("current path: " + path)
    currentDirId.push(dir_id);
    setCurrentDirId(currentDirId);
    console.log("current dir ids: " + currentDirId)
    console.log(documentsData);
    setParent_id(dir_id)
    console.log("Parent_id: " + parent_id);
  }

  const deleteDirectoryClickHandler = async (dir_id) => {
    console.log("Garbage Icon clicked: " + dir_id)
    const deleteDir = await deleteDirectory(dir_id);
    console.log("Directory Deleted: " + deleteDir);
  }

  const deleteFileClickHandler = async (dir_id) => {
    const delFile = await deleteFile(dir_id);
    console.log("File Deleted: " + delFile);
  }

  const updateDocumentClickHandler = async(type, newName, dir_id, parent_id) => {
    // const newNameFromChildren = {}
    console.log(type,newName, dir_id, parent_id)
    const updateFile = await updateDocument(type, newName, dir_id, parent_id);
    console.log("Document Updated: " + updateFile);

    const documentsData = await getDocuments(parent_id);
    console.log("Response from getDocuments function: " + JSON.stringify(documentsData));
    setDocuments(documentsData);
  }

  const formSubmitHandler = async (e) => {
    e.preventDefault();
    console.log("submitFormHandler: " + type, name, parent_id);
    const createDoc = await createDocument(type, name, parent_id);
    console.log(createDoc);
    // const documentsData = await getDocuments(currentDirId[currentDirId.length - 1]);
    console.log("Parent Id FormSubmitHandler: " + parent_id)
    const documentsData = await getDocuments(parent_id);
    console.log("Function call after creating Document: " + JSON.stringify(documentsData));
    setDocuments(documentsData);
    
    // const documentsData = await getDocuments(currentDirId[currentDirId.length - 1]);
    // setDocuments(documentsData);
  }

  const directoryClickHandler = (id) => {
    console.log("Directory onClick: " + id)
    // console.log("Directory onClick: " + props.id)
  }

  // const refreshDocumentsDisplay = async () => {
  //   let dir_id = currentDirId[currentDirId.length - 1];
  //     // console.log("dir_id: " + dir_id)
  //     const documentsData = await getDocuments(dir_id);
  //     setDocuments(documentsData);  
  // }

  return (
    <>
      <Header />
      <div>
        <div className="row">
          <div className="col">
            <h3 className="text-start text-decoration-underline bebas-neue-regular mb-3">Current Directory</h3>
            {<h4>{"/ " + path.join(" / ")}</h4>}
            {path.length === 0 ? <></> : <button className='btn btn-secondary mt-2 rounded-pill float-none' onClick={goBackDir}>Go Back</button>}
          </div>
        </div>
        <hr/>
        <div className='row'>
          <div className='col me-1'>
            <h3 className="text-start text-decoration-underline bebas-neue-regular">Directories</h3>
            {Object.keys(documents.directories).length > 1 ? documents.directories.map(result => <Directory key={result.id} id={result.id} name= {result.name} parent_id={parent_id} type="directory" delDir={deleteDirectoryClickHandler} dirId={documentsClickHandler} updateDir={updateDocumentClickHandler} />) : <p>Nothing to show</p>}
          </div>

          <div className='col ms-1'>
            <h3 className="text-end text-decoration-underline bebas-neue-regular">Files</h3>
            {Object.keys(documents.files).length > 1 ? documents.files.map(result => <File className='ms-0 ps-0' key={result.id} id={result.id} name= {result.name} parent_id={parent_id} type="file" delFile={deleteFileClickHandler} dirId={directoryClickHandler} updateDir={updateDocumentClickHandler} />) : <p>Nothing to show</p>}
          </div> 
        </div>       
        <hr/>
        <h3 className="text-start text-decoration-underline bebas-neue-regular">Create Documents</h3>
        <form onSubmit={formSubmitHandler} className="form-control no-border">
          <div className="row">
            <div className='col-4 mt-2'>
              <div className='form-check text-start' onClick={updateType}>
                <input type='radio' name='doc_type' value='directory' id='dir' defaultChecked onClick={updateType}/> <label htmlFor="dir" onClick={updateType}><i className="bi bi-folder-fill pe-1" onClick={updateType}></i>Directory</label>
              </div>
              <div className='form-check text-start' onClick={updateType}>
                <input type='radio' name='doc_type' value='file' id='file' onClick={updateType} /> <label htmlFor="file" onClick={updateType}><i className="bi bi-file-earmark-text pe-1" onClick={updateType}></i>File</label>
              </div>
            </div>
            <div className='col'>
              <div className="input-group">
                <input type="text" className="form-control mt-2 w-25" placeholder="Name of document" onChange={updateName} />
              </div>
            </div>
            <div className='col-3'>
              <button type='submit' className='btn btn-secondary mt-2 rounded-pill'>Create</button>
            </div>
          </div>
        </form>
      </div>
    </>
  )
}

export default App
