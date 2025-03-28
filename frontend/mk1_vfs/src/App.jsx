import { React, useState, useEffect } from 'react';
// import axios from 'axios';
import { getDirectories } from "../services/mk1-vfs_service";
import './App.css'


function App() {
  const [results, setResults] = useState({"directories":[{"name":"Unavailable"}]})
  console.log("Results when initializing the page: " + JSON.stringify(results));

  // useEffect(() => {
  //   axios.get(baseURL)
  //     .then(response => {
  //       console.error('Updating data with response:' + JSON.stringify(response));
  //       setData(response.data);
  //       console.log(data)
  //     })
  //     .catch(error => {
  //       console.error('Error fetching data:', error);
  //     });
  // }, []);

  const buttonClickHandler = async () => {
    const response = await getDirectories();
    console.log("Response from getDirectories function: " + JSON.stringify(response))
    setResults(response)
  }
  
  return (
    <>
      <div>
        <h1>MK1 Virtual File System</h1>
        {Object.keys(results).length === 1 ? <p>No Data Available</p> : <p> Data Updated </p>}
        {Object.keys(results).length > 1 ? <p>{JSON.stringify(results.directories[0].name)}</p> : <p></p>}
        {JSON.stringify(results.directories[0].name)}
        <br/>
        <button onClick={buttonClickHandler}>Fetch Data</button>
      </div>
    </>
  )
}

export default App
