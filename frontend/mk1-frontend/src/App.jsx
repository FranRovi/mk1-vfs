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
  const [documents, setDocuments] = useState({directories:[],files:[]});
  const [currentDirId, setCurrentDirId] = useState([])
  const [path, setPath] = useState([])


  const findRoot = async () => {
    const response = await getRoot()
    setDocuments(response)
  }
  
  useEffect(() => {
    findRoot()
  }, [])

  const updateName = (e) => {
    setName((prev) => e.target.value);
  }

  const updateType = (e) => {
    if (e.target.value === 'directory' && type !== 'directory'
    ) {
      setType(() => 'directory')
    }

    if (e.target.value === 'file' && type !== 'file'
    ) {
      setType(() => 'file')
    }
  }

  const goBackDir = async () => {
    path.pop()
    setPath(path);
    currentDirId.pop();
    setCurrentDirId(currentDirId);
    setParent_id(currentDirId[currentDirId.length - 1])
    if (currentDirId.length === 0) {
      setParent_id(null);
      const response = await getRoot()
      setDocuments(response)
    } else {
      let dir_id = currentDirId[currentDirId.length - 1];
      setParent_id(dir_id);
      const documentsData = await getDocuments(dir_id);
      setDocuments(documentsData);  
    }
  }

  const documentsClickHandler = async (dir_id, dir_name) => {
    const documentsData = await getDocuments(dir_id);
    setDocuments(documentsData);
    path.push(dir_name);
    setPath(path);
    currentDirId.push(dir_id);
    setCurrentDirId(currentDirId);
    setParent_id(dir_id)
  }

  const deleteDirectoryClickHandler = async (dir_id) => {
    await deleteDirectory(dir_id);
    const documentsData = await getDocuments(parent_id);
    setDocuments(documentsData);
  }

  const deleteFileClickHandler = async (dir_id) => {
    await deleteFile(dir_id);
    const documentsData = await getDocuments(parent_id);
    setDocuments(documentsData);
  }

  const updateDocumentClickHandler = async(type, newName, dir_id, parent_id) => {
    await updateDocument(type, newName, dir_id, parent_id);
    const documentsData = await getDocuments(parent_id);
    setDocuments(documentsData);
  }

  const formSubmitHandler = async (e) => {
    e.preventDefault();
    await createDocument(type, name, parent_id);
    const documentsData = await getDocuments(parent_id);
    setDocuments(documentsData);
  }

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
            {Object.keys(documents.directories).length >= 1 ? documents.directories.map(result => <Directory key={result.id} id={result.id} name= {result.name} parent_id={parent_id} type="directory" delDir={deleteDirectoryClickHandler} dirId={documentsClickHandler} updateDir={updateDocumentClickHandler} />) : <p>Nothing to show</p>}
          </div>

          <div className='col ms-1'>
            <h3 className="text-end text-decoration-underline bebas-neue-regular">Files</h3>
            {Object.keys(documents.files).length >= 1 ? documents.files.map(result => <File className='ms-0 ps-0' key={result.id} id={result.id} name= {result.name} parent_id={parent_id} type="file" delFile={deleteFileClickHandler} dirId={documentsClickHandler} updateDir={updateDocumentClickHandler} />) : <p>Nothing to show</p>}
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
