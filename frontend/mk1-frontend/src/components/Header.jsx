import React from 'react';
import './Header.css';

const Header = () => {
    return (
        <>
            <nav className="navbar navbar-dark bg-dark mb-3">
                <div className="container-fluid">
                    <div className='square'>   
                        <a className="navbar-brand" href="https://mk1.ai/">
                        <img className="ps-2" src="https://mk1.ai/logo.png" alt="mk1 logo" width="52" height="30" class="d-inline-block align-text-top" />
                        </a>
                    </div>
                    
                    <h5 className="text-light ultra-regular">Virtual File System</h5>
                </div>
            </nav>
        </>
    )
};

export default Header;