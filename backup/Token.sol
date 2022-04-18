// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import { Base64 } from './libraries/Base64.sol';
import { IToken } from './interfaces/IToken.sol';
import { IStorage } from './interfaces/IStorage.sol';

contract Token is IToken, ERC721, Ownable {
    uint256 private _totalSupply;
    IStorage public assets;

    constructor(IStorage _assets) ERC721('Never Gonna Give You Up', 'RICKROLL') {
        assets = _assets;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function tokenUri(uint256 tokenId) public view override returns (string memory) {
        string memory html = '<script>let playing=false</script><img src="https://cloudflare-ipfs.com/ipfs/QmdmPHWQBzV24GvbwCszm2AnWetBENeBP2UStuETsyAp1C" width="400" /><br><svg onclick=\'(()=>{const elms=[this.getElementById("play"),this.getElementById("stop")];if(playing){try{song1.pause()}catch(e){};try{song2.pause()}catch(e){};elms[0].style.opacity=1;elms[1].style.opacity=0;playing = false}else{try{song1.play()}catch(e){};try{song2.play()}catch(e){};elms[0].style.opacity=0;elms[1].style.opacity=1;playing = true}})()\' style="cursor: pointer;position: absolute;top: 260px;left: 360px;z-index: 100;" width="32px" height="32px" viewBox="0 0 32 32"><circle cx="16" cy="16" r="16" fill="#f0f0f0" /><polygon id="stop" style="opacity:0;" points="10,10 22,10, 22,22 10,22" fill="" /><polygon id="play" points="10,7 10,25 25,15" fill="" /></svg><audio src="" id="song1" volume="0.1" style="display: none;" loop="true"></audio><audio src="" id="song2" volume="0.1" style="display: none;" loop="true"></audio><script>const songs = [song1, song2];const tracks = location.hash.slice(1).split("#");const betterQuality = ["", "https://cloudflare-ipfs.com/ipfs/QmWmmmrQB3iFXHPNStyL7GvgZcifGz3JrzcFbSLQzyevjn"];for(let i =0;i<songs.length;i++) songs[i].src = (navigator.onLine && betterQuality[i]) || tracks[i];</script>';
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "RickRolled #1", "description": "Never Gonna Give You Up is the debut single recorded by English singer and songwriter Rick Astley, released on 27 July 1987.", "image": "https://cloudflare-ipfs.com/ipfs/QmdmPHWQBzV24GvbwCszm2AnWetBENeBP2UStuETsyAp1C", "animation_url": "',
                            'data:text/html;base64,',
                            Base64.encode(bytes(html)),
                            '#',
                            '#',
                            getAudioAssetBase64(0),
                            '", "audio": "',
                            getAudioAssetBase64(0),
                            '", "external_url": "https://en.wikipedia.org/wiki/Rick_Astley", "attributes": [{"trait_type": "On-chain", "value": "Absolutely"}, {"trait_type": "Artist", "value": "Rick Astley"}, {"trait_type": "Rickrolled", "value": "You"}, {"trait_type": "Favorite Fruit", "value": "Banana"}, {"trait_type": "Favorite Blockchain", "value": "Ethereum"}], "composer": "Stock Aitken Waterman"}'
                        )
                    )
                )
            );
    }

    function getAudioAssetBase64(uint16 _assetId) public view override returns (string memory) {
        return string(abi.encodePacked('data:audio/mp3;base64,', Base64.encode(assets.getAssetBytes(_assetId))));
    }
}