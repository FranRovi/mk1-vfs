import axios from "axios";


const baseURL = "http://localhost:8000";

export const getDirectories = async () => {
    const response = await axios.get(`${baseURL}/directories`)
    return response.data
}

export const getChildren = async (parent_id) => {
    const response = await axios.get(`${baseURL}/directories?parent_id=${parent_id}`)
    return response.data
}

export const deleteDirectory = async (dir_id) => {
    const response = await axios.delete(`${baseURL}/directories/${dir_id}`,{
        data: {
            recursive: true
        }
    });
    console.log(response)
    return
    // return response.data
}

export const getFiles = async () => {
    const response = await axios.get(`${baseURL}/files/66102b24-60ef-4a7c-bce1-1b2e6d071811`)
    return response.data
}

// export const getDirectoriesWithParams = async () => {
//     const response = await axios.get(baseURL)
//     return response.data
// }