import axios from "axios";


const baseURL = "http://localhost:8000/directories";

export const getDirectories = async () => {
    const response = await axios.get(baseURL)
    return response.data
}

export const getDirectoriesWithParams = async () => {
    const response = await axios.get(baseURL)
    return response.data
}