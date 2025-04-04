import axios from "axios";


const baseURL = "http://localhost:8000";

export const getRoot = async () => {
    const response = await axios.get(`${baseURL}/directories`)
    return response.data
}

export const getDocuments = async (dir_id) => {
    let response;
    if (dir_id === null){
        response = await axios.get(`${baseURL}/directories`)
    } else {
        response = await axios.get(`${baseURL}/directories?parent_id=${dir_id}`)
    }
    return response.data
}


export const createDocument = async (type, name, parent_id) => {
    let name_body = name;
    let parent_id_body = parent_id;
    if (type === 'directory') {
        await axios.post(`${baseURL}/directories`, {
            name: name_body,
            parent_id: parent_id_body,
        });
    } else {
        await axios.post(`${baseURL}/files`, {
            filename: name_body,
            parent_id: parent_id_body,
        });
    }
}


export const updateDocument = async (type, name, id, parent_id) => {
    let name_body = name;
    let parent_id_body = parent_id;
    if (type === 'directory') {
        await axios.patch(`${baseURL}/directories/${id}`, {
            updates: {
                name: name_body,
                parent_id: parent_id_body,
            }
        });
    } else {
        await axios.patch(`${baseURL}/files/${id}`, {
            updates: {
                name: name_body,
                parent_id: parent_id_body,
            }
        });
    }
}


export const deleteDirectory = async (dir_id) => {
    await axios.delete(`${baseURL}/directories/${dir_id}`,{
        data: {
            recursive: true
        }
    });
    return
}


export const deleteFile = async (dir_id) => {
    await axios.delete(`${baseURL}/files/${dir_id}`);
    return
}
