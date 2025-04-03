import React, { useState, useEffect } from 'react';
import Header from './components/Header';
import File from './components/File'
import Directory from './components/Directory';
import { deleteDirectory, createDocument, getDocuments, deleteFile, updateDocument, getRoot } from "../src/services/frontend_services";

import 'bootstrap-icons/font/bootstrap-icons.css';
import './App.css'

function App() {
  const [type, setType] = useState("");
  const [name, setName] = useState("");
  const [parent_id, setParent_id] = useState("bec46267-cc3c-45bf-9bd2-52928c6f44ef") // Desktop ID
  // ("66102b24-60ef-4a7c-bce1-1b2e6d071811");
  // 2165252f-7fbe-4299-afc3-d1dc35e5937a Work ID
  // const [isEdit, setIsEdit] = useState(true)
  // const [updatedName, setUpdatedName] = useState();

  const [documents, setDocuments] = useState({directories:[],files:[]});
  const [currentDirId, setCurrentDirId] = useState([])
  const [path, setPath] = useState([])

  // const [testDirFetch, setTestDirFetch] = useState("")

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
    console.log("current path: " + path)
    path.pop()
    console.log("current path: " + path)
    setPath(path);
    console.log("current dir ids: " + currentDirId)
    currentDirId.pop();
    setCurrentDirId(currentDirId);
    console.log("current dir ids: " + currentDirId)
    if (currentDirId.length === 0) {
      const response = await getRoot()
      setDocuments(response)
    } else {
      let dir_id = currentDirId[currentDirId.length - 1];
      console.log("dir_id: " + dir_id)
      const documentsData = await getDocuments(dir_id);
      setDocuments(documentsData);  
    }


    // console.log("Current Path: " + path);
    // const newPath = path.pop()
    // console.log("New Path: " + newPath) 
    
    // path.pop()
    // console.log(path)
    // setPath(prev => prev.pop())
    // console.log(path)
    // setPath(newPath)
  }

  // const updateDocument = () => {

  // }
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
  }

  // const filesClickHandler = async () => {
  //   const filesData = await getFiles();
  //   console.log("Response from getFiles function: " + JSON.stringify(filesData))
  //   setFilesResults(filesData)
  // }

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

  const directoryClickHandler = (id) => {
    console.log("Directory onClick: " + id)
    // console.log("Directory onClick: " + props.id)
  }

  return (
    <>
      <Header />
      {/* <h1>MK1 Virtual File System</h1>
      <h2>*** Front End ***</h2> */}
      <div>
        <div className="row">
          <div className="col">
          <h3 className="text-start text-decoration-underline bebas-neue-regular mb-5">Current Directory</h3>
            {/* <div className="row"> */}
              {/* <div className="d-flex"> */}
                {/* {<h4>{ path.length >= 1 ? path.join(" / ") : path[0] }</h4>} */}
                {/* {path} */}
                {<h4>{"/ " + path.join(" / ")}</h4>}

                {path.length === 0 ? <></> : <button className='btn btn-secondary mt-2 rounded-pill float-none' onClick={goBackDir}>Go Back</button>}
              </div>
            {/* </div> */}
            
          {/* </div> */}
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
        {/* <hr/> */}
        <button className='btn btn-secondary text-center mt-5' onClick={documentsClickHandler}>Fetch Documents</button>

        <hr/>

        
        <h3 className="text-start text-decoration-underline bebas-neue-regular">Create Documents</h3>
        <form onSubmit={formSubmitHandler} className="form-control no-border">
          <div className="row">
            <div className='col-4 mt-2'>
              <div className='form-check text-start' onClick={updateType}>
                <input type='radio' name='doc_type' value='directory' id='dir' onClick={updateType}/> <label htmlFor="dir" onClick={updateType}><i className="bi bi-folder-fill pe-1" onClick={updateType}></i>Directory</label>
              </div>
              <div className='form-check text-start' onClick={updateType}>
                <input type='radio' name='doc_type' value='file' id='file' onClick={updateType} /> <label htmlFor="file" onClick={updateType}><i className="bi bi-file-earmark-text pe-1" onClick={updateType}></i>File</label>
              </div>
            </div>
            <div className='col'>
              <div className="input-group">
                {/* <span class="input-group-text" id="basic-addon1">@</span> */}
                <input type="text" className="form-control mt-2 w-25" placeholder="Name of document" onChange={updateName} />
              </div>
            </div>
            <div className='col-3'>
              <button type='submit' className='btn btn-secondary mt-2 rounded-pill'>Create</button>
            </div>
            {/* {<pre>{type} <span>   </span> {name}</pre>} */}
          </div>
        </form>
      </div>
    {/* </div> */}
    </>
  )
}

export default App
