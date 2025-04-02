import React from 'react';
import './Header.css';

const Header = () => {
    return (
        <>
            <nav class="navbar navbar-dark bg-dark mb-3">
                <div class="container-fluid">
                    <div className='square'>   
                        <a class="navbar-brand" href="https://mk1.ai/">
                        <img className="ps-1" src="https://mk1.ai/logo.png" alt="mk1 logo" width="50" height="28" class="d-inline-block align-text-top" />
                        </a>
                    </div>
                    
                    <h5 className="text-light">Virtual File System</h5>
                </div>
            </nav>
        </>
    )
};

export default Header;