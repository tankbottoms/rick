// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import {Base64} from './libraries/Base64.sol';
import {IToken} from './interfaces/IToken.sol';
import {IStorage} from './interfaces/IStorage.sol';

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
        string
            memory html = unicode'<link rel="stylesheet" type="text/css" href="https://play.ertdfgcvb.xyz/css/simple_console.css"><style type="text/css" media="screen">html, body {	padding: 0;	margin: 0;	font-size: 1em;	line-height: 1.2;font-family: "Simple Console", monospace;}pre {	position: absolute;	margin:0;padding:0;	left:0;	top:0;width:1000px;height:2000px;color: white;opacity: 0.5;font-family: inherit;transform: scale(0.7);transform-origin:10px 10px;}</style><pre></pre><script src="data:text/javascript;base64,dmFyIGU9e3ByZWZlcnJlZEVsZW1lbnROb2RlTmFtZToiUFJFIixyZW5kZXI6ZnVuY3Rpb24oZSxzKXtjb25zdCBpPWUuc2V0dGluZ3MuZWxlbWVudDtlLnJvd3M9PW4mJmUuY29scz09b3x8KG89ZS5jb2xzLG49ZS5yb3dzLHQubGVuZ3RoPTApO2Zvcig7aS5jaGlsZEVsZW1lbnRDb3VudDxuOyl7Y29uc3QgZT1kb2N1bWVudC5jcmVhdGVFbGVtZW50KCJzcGFuIik7ZS5zdHlsZS5kaXNwbGF5PSJibG9jayIsaS5hcHBlbmRDaGlsZChlKX1mb3IoO2kuY2hpbGRFbGVtZW50Q291bnQ+bjspaS5yZW1vdmVDaGlsZChpLmxhc3RDaGlsZCk7Zm9yKGxldCBjPTA7YzxuO2MrKyl7Y29uc3Qgbj1jKm87bGV0IGE9ITE7Zm9yKGxldCBlPTA7ZTxvO2UrKyl7Y29uc3Qgbz1lK24sbD1zW29dLGk9dFtvXTtyKGwsaSl8fChhPSEwLHRbb109ey4uLmx9KX1pZigwPT1hKWNvbnRpbnVlO2xldCBkPSIiLGY9e30saD0hMTtmb3IobGV0IHQ9MDt0PG87dCsrKXtjb25zdCBvPXNbdCtuXTtpZihvLmJlZ2luSFRNTCYmKGgmJihkKz0iPC9zcGFuPiIsZj17fSxoPSExKSxkKz1vLmJlZ2luSFRNTCksIWwobyxmKSl7aCYmKGQrPSI8L3NwYW4+Iik7Y29uc3QgdD1vLmNvbG9yPT09ZS5zZXR0aW5ncy5jb2xvcj9udWxsOm8uY29sb3Isbj1vLmJhY2tncm91bmRDb2xvcj09PWUuc2V0dGluZ3MuYmFja2dyb3VuZENvbG9yP251bGw6by5iYWNrZ3JvdW5kQ29sb3Iscj1vLmZvbnRXZWlnaHQ9PT1lLnNldHRpbmdzLmZvbnRXZWlnaHQ/bnVsbDpvLmZvbnRXZWlnaHQ7bGV0IGw9IiI7dCYmKGwrPSJjb2xvcjoiK3QrIjsiKSxuJiYobCs9ImJhY2tncm91bmQ6IituKyI7IiksciYmKGwrPSJmb250LXdlaWdodDoiK3IrIjsiKSxsJiYobD0nIHN0eWxlPSInK2wrJyInKSxkKz0iPHNwYW4iK2wrIj4iLGg9ITB9ZCs9by5jaGFyLGY9byxvLmVuZEhUTUwmJihoJiYoZCs9Ijwvc3Bhbj4iLGY9e30saD0hMSksZCs9by5lbmRIVE1MKX1oJiYoZCs9Ijwvc3Bhbj4iKSxpLmNoaWxkTm9kZXNbY10uaW5uZXJIVE1MPWR9fX07Y29uc3QgdD1bXTtsZXQgbyxuO2Z1bmN0aW9uIHIoZSx0KXtyZXR1cm4ib2JqZWN0Ij09dHlwZW9mIGUmJigib2JqZWN0Ij09dHlwZW9mIHQmJihlLmNoYXI9PT10LmNoYXImJihlLmZvbnRXZWlnaHQ9PT10LmZvbnRXZWlnaHQmJihlLmNvbG9yPT09dC5jb2xvciYmZS5iYWNrZ3JvdW5kQ29sb3I9PT10LmJhY2tncm91bmRDb2xvcikpKSl9ZnVuY3Rpb24gbChlLHQpe3JldHVybiBlLmZvbnRXZWlnaHQ9PT10LmZvbnRXZWlnaHQmJihlLmNvbG9yPT09dC5jb2xvciYmZS5iYWNrZ3JvdW5kQ29sb3I9PT10LmJhY2tncm91bmRDb2xvcil9dmFyIHM9e3ByZWZlcnJlZEVsZW1lbnROb2RlTmFtZToiQ0FOVkFTIixyZW5kZXI6ZnVuY3Rpb24oZSx0KXtjb25zdCBvPWUuc2V0dGluZ3MuZWxlbWVudCxuPWRldmljZVBpeGVsUmF0aW8scj1lLmNvbHMsbD1lLnJvd3Mscz1lLm1ldHJpY3MsaT1zLmNlbGxXaWR0aCxjPU1hdGgucm91bmQocy5saW5lSGVpZ2h0KSxhPWUuc2V0dGluZ3M7YS5jYW52YXNTaXplPyhvLndpZHRoPWEuY2FudmFzU2l6ZS53aWR0aCpuLG8uaGVpZ2h0PWEuY2FudmFzU2l6ZS5oZWlnaHQqbixvLnN0eWxlLndpZHRoPWEuY2FudmFzU2l6ZS53aWR0aCsicHgiLG8uc3R5bGUuaGVpZ2h0PWEuY2FudmFzU2l6ZS5oZWlnaHQrInB4Iik6KG8ud2lkdGg9ZS53aWR0aCpuLG8uaGVpZ2h0PWUuaGVpZ2h0Km4pO2NvbnN0IGQ9IiAiK3MuZm9udFNpemUrInB4ICIrcy5mb250RmFtaWx5LGY9YSYmYS5iYWNrZ3JvdW5kQ29sb3I/YS5iYWNrZ3JvdW5kQ29sb3I6IndoaXRlIixoPWEmJmEuY29sb3I/YS5jb2xvcjoiYmxhY2siLHU9YSYmYS5mb250V2VpZ2h0P2EuY29sb3I6IjQwMCIscD1vLmdldENvbnRleHQoIjJkIik7aWYocC5maWxsU3R5bGU9ZixwLmZpbGxSZWN0KDAsMCxvLndpZHRoLG8uaGVpZ2h0KSxwLnNhdmUoKSxwLnNjYWxlKG4sbikscC5maWxsU3R5bGU9aCxwLnRleHRCYXNlbGluZT0idG9wIixhLmNhbnZhc09mZnNldCl7Y29uc3QgZT1hLmNhbnZhc09mZnNldCx0PU1hdGgucm91bmQoImF1dG8iPT1lLng/KG8ud2lkdGgvbi1yKmkpLzI6ZS54KSxzPU1hdGgucm91bmQoImF1dG8iPT1lLnk/KG8uaGVpZ2h0L24tbCpjKS8yOmUueSk7cC50cmFuc2xhdGUodCxzKX1pZigiY2VudGVyIj09YS50ZXh0QWxpZ24pZm9yKGxldCBlPTA7ZTxsO2UrKyl7Y29uc3QgbD1lKnIscz1bXTtsZXQgaT0wO2ZvcihsZXQgZT0wO2U8cjtlKyspe2NvbnN0IG89dFtsK2VdO3AuZm9udD0oby5mb250V2VpZ2h0fHx1KStkO2NvbnN0IG49cC5tZWFzdXJlVGV4dChvLmNoYXIpLndpZHRoO2krPW4sc1tlXT1ufWxldCBhPS41KihvLndpZHRoL24taSk7Y29uc3QgZz1lKmM7Zm9yKGxldCBlPTA7ZTxyO2UrKyl7Y29uc3Qgbz10W2wrZV0sbj1hO28uYmFja2dyb3VuZENvbG9yJiZvLmJhY2tncm91bmRDb2xvciE9ZiYmKHAuZmlsbFN0eWxlPW8uYmFja2dyb3VuZENvbG9yfHxmLHAuZmlsbFJlY3QoTWF0aC5yb3VuZChuKSxnLE1hdGguY2VpbChzW2VdKSxjKSkscC5mb250PShvLmZvbnRXZWlnaHR8fHUpK2QscC5maWxsU3R5bGU9by5jb2xvcnx8aCxwLmZpbGxUZXh0KG8uY2hhcixhLGcpLGErPXNbZV19fWVsc2UgZm9yKGxldCBlPTA7ZTxsO2UrKylmb3IobGV0IG89MDtvPHI7bysrKXtjb25zdCBuPXRbZSpyK29dLGw9byppLHM9ZSpjO24uYmFja2dyb3VuZENvbG9yJiZuLmJhY2tncm91bmRDb2xvciE9ZiYmKHAuZmlsbFN0eWxlPW4uYmFja2dyb3VuZENvbG9yfHxmLHAuZmlsbFJlY3QoTWF0aC5yb3VuZChsKSxzLE1hdGguY2VpbChpKSxjKSkscC5mb250PShuLmZvbnRXZWlnaHR8fHUpK2QscC5maWxsU3R5bGU9bi5jb2xvcnx8aCxwLmZpbGxUZXh0KG4uY2hhcixsLHMpfXAucmVzdG9yZSgpfX07Y2xhc3MgaXtjb25zdHJ1Y3Rvcigpe3RoaXMuZnJhbWVzPTAsdGhpcy5wdGltZT0wLHRoaXMuZnBzPTB9dXBkYXRlKGUpe3JldHVybiB0aGlzLmZyYW1lcysrLGU+PXRoaXMucHRpbWUrMWUzJiYodGhpcy5mcHM9MWUzKnRoaXMuZnJhbWVzLyhlLXRoaXMucHRpbWUpLHRoaXMucHRpbWU9ZSx0aGlzLmZyYW1lcz0wKSx0aGlzLmZwc319dmFyIGM9ZnVuY3Rpb24oZSx0KXt0cnl7cmV0dXJuIGxvY2FsU3RvcmFnZS5zZXRJdGVtKGUsSlNPTi5zdHJpbmdpZnkodCkpLCEwfWNhdGNoKGUpe3JldHVybiExfX0sYT1mdW5jdGlvbihlLHQ9e30pe2NvbnN0IG89SlNPTi5wYXJzZShsb2NhbFN0b3JhZ2UuZ2V0SXRlbShlKSk7cmV0dXJuIE9iamVjdC5hc3NpZ24odCxvKSx0fSxkPSIxLjEiO2NvbnN0IGY9e2NhbnZhczpzLHRleHQ6ZX0saD17ZWxlbWVudDpudWxsLGNvbHM6MCxyb3dzOjAsb25jZTohMSxmcHM6MzAscmVuZGVyZXI6InRleHQiLGFsbG93U2VsZWN0OiExLHJlc3RvcmVTdGF0ZTohMX0sdT1bImJhY2tncm91bmRDb2xvciIsImNvbG9yIiwiZm9udEZhbWlseSIsImZvbnRTaXplIiwiZm9udFdlaWdodCIsImxldHRlclNwYWNpbmciLCJsaW5lSGVpZ2h0IiwidGV4dEFsaWduIl07ZnVuY3Rpb24gcnVuKGUsdCxvPXt9KXtyZXR1cm4gbmV3IFByb21pc2UoKGZ1bmN0aW9uKG4pe2NvbnN0IHI9ey4uLmgsLi4udCwuLi5lLnNldHRpbmdzfSxsPXt0aW1lOjAsZnJhbWU6MCxjeWNsZTowfSxzPSJjdXJyZW50U3RhdGUiO2xldCBkO3IucmVzdG9yZVN0YXRlJiYoYShzLGwpLGwuY3ljbGUrKyksci5lbGVtZW50PyJjYW52YXMiPT1yLnJlbmRlcmVyPyJDQU5WQVMiPT1yLmVsZW1lbnQubm9kZU5hbWU/ZD1mW3IucmVuZGVyZXJdOmNvbnNvbGUud2FybigiVGhpcyByZW5kZXJlciBleHBlY3RzIGEgY2FudmFzIHRhcmdldCBlbGVtZW50LiIpOiJDQU5WQVMiIT1yLmVsZW1lbnQubm9kZU5hbWU/ZD1mW3IucmVuZGVyZXJdOmNvbnNvbGUud2FybigiVGhpcyByZW5kZXJlciBleHBlY3RzIGEgdGV4dCB0YXJnZXQgZWxlbWVudC4iKTooZD1mW3IucmVuZGVyZXJdfHxmLnRleHQsci5lbGVtZW50PWRvY3VtZW50LmNyZWF0ZUVsZW1lbnQoZC5wcmVmZXJyZWRFbGVtZW50Tm9kZU5hbWUpLGRvY3VtZW50LmJvZHkuYXBwZW5kQ2hpbGQoci5lbGVtZW50KSk7Zm9yKGNvbnN0IGUgb2YgdSlyW2VdJiYoci5lbGVtZW50LnN0eWxlW2VdPXJbZV0pO2NvbnN0IHA9W10sbT17eDowLHk6MCxwcmVzc2VkOiExLHB4OjAscHk6MCxwcHJlc3NlZDohMX07ci5lbGVtZW50LmFkZEV2ZW50TGlzdGVuZXIoInBvaW50ZXJtb3ZlIiwoZT0+e2NvbnN0IHQ9ci5lbGVtZW50LmdldEJvdW5kaW5nQ2xpZW50UmVjdCgpO20ueD1lLmNsaWVudFgtdC5sZWZ0LG0ueT1lLmNsaWVudFktdC50b3AscC5wdXNoKCJwb2ludGVyTW92ZSIpfSkpLHIuZWxlbWVudC5hZGRFdmVudExpc3RlbmVyKCJwb2ludGVyZG93biIsKGU9PnttLnByZXNzZWQ9ITAscC5wdXNoKCJwb2ludGVyRG93biIpfSkpLHIuZWxlbWVudC5hZGRFdmVudExpc3RlbmVyKCJwb2ludGVydXAiLChlPT57bS5wcmVzc2VkPSExLHAucHVzaCgicG9pbnRlclVwIil9KSksci5lbGVtZW50LnN0eWxlLmZvbnRTdHJlY2g9Im5vcm1hbCIsci5hbGxvd1NlbGVjdHx8eShyLmVsZW1lbnQpLGRvY3VtZW50LmZvbnRzLnJlYWR5LnRoZW4oKHQ9PntsZXQgbj0zOyFmdW5jdGlvbiB0KCl7LS1uPjA/cmVxdWVzdEFuaW1hdGlvbkZyYW1lKHQpOmZ1bmN0aW9uKCl7eD1iKHIuZWxlbWVudCk7Y29uc3QgdD1nKGwscix4LHcpOyJmdW5jdGlvbiI9PXR5cGVvZiBlLmJvb3QmJmUuYm9vdCh0LEMsbyk7cmVxdWVzdEFuaW1hdGlvbkZyYW1lKE0pfSgpfSgpfSkpO2NvbnN0IHc9bmV3IGksUz1PYmplY3QuZnJlZXplKHtjb2xvcjpyLmNvbG9yLGJhY2tncm91bmRDb2xvcjpyLmJhY2tncm91bmRDb2xvcixmb250V2VpZ2h0OnIuZm9udFdlaWdodH0pLEM9W107bGV0IHg7bGV0IHY9MDtjb25zdCBrPTFlMy9yLmZwcyxOPWwudGltZTtsZXQgRSxXO2Z1bmN0aW9uIE0odCl7Y29uc3QgaT10LXY7aWYoaTxrKXJldHVybiB2b2lkKHIub25jZXx8cmVxdWVzdEFuaW1hdGlvbkZyYW1lKE0pKTtjb25zdCBhPWcobCxyLHgsdyk7dy51cGRhdGUodCksdj10LWklayxsLnRpbWU9dCtOLGwuZnJhbWUrKyxjKHMsbCk7Y29uc3QgZj17eDpNYXRoLm1pbihhLmNvbHMtMSxtLngveC5jZWxsV2lkdGgpLHk6TWF0aC5taW4oYS5yb3dzLTEsbS55L3gubGluZUhlaWdodCkscHJlc3NlZDptLnByZXNzZWQscDp7eDptLnB4L3guY2VsbFdpZHRoLHk6bS5weS94LmxpbmVIZWlnaHQscHJlc3NlZDptLnBwcmVzc2VkfX07aWYobS5weD1tLngsbS5weT1tLnksbS5wcHJlc3NlZD1tLnByZXNzZWQsRSE9YS5jb2xzfHxXIT1hLnJvd3Mpe0U9YS5jb2xzLFc9YS5yb3dzLEMubGVuZ3RoPWEuY29scyphLnJvd3M7Zm9yKGxldCBlPTA7ZTxDLmxlbmd0aDtlKyspQ1tlXT17Li4uUyxjaGFyOiIgIn19aWYoImZ1bmN0aW9uIj09dHlwZW9mIGUucHJlJiZlLnByZShhLGYsQyxvKSwiZnVuY3Rpb24iPT10eXBlb2YgZS5tYWluKWZvcihsZXQgdD0wO3Q8YS5yb3dzO3QrKyl7Y29uc3Qgbj10KmEuY29scztmb3IobGV0IHI9MDtyPGEuY29scztyKyspe2NvbnN0IGw9cituLHM9ZS5tYWluKHt4OnIseTp0LGluZGV4Omx9LGEsZixDLG8pO0NbbF09Im9iamVjdCI9PXR5cGVvZiBzJiZudWxsIT09cz97Li4uQ1tsXSwuLi5zfTp7Li4uQ1tsXSxjaGFyOnN9LEJvb2xlYW4oQ1tsXS5jaGFyKXx8MD09PUNbbF0uY2hhcnx8KENbbF0uY2hhcj0iICIpfX1mb3IoImZ1bmN0aW9uIj09dHlwZW9mIGUucG9zdCYmZS5wb3N0KGEsZixDLG8pLGQucmVuZGVyKGEsQyxyKTtwLmxlbmd0aD4wOyl7Y29uc3QgdD1wLnNoaWZ0KCk7dCYmImZ1bmN0aW9uIj09dHlwZW9mIGVbdF0mJmVbdF0oYSxmLEMpfXIub25jZXx8cmVxdWVzdEFuaW1hdGlvbkZyYW1lKE0pLG4oYSl9fSkpfWZ1bmN0aW9uIGcoZSx0LG8sbil7Y29uc3Qgcj10LmVsZW1lbnQuZ2V0Qm91bmRpbmdDbGllbnRSZWN0KCksbD10LmNvbHN8fE1hdGguZmxvb3Ioci53aWR0aC9vLmNlbGxXaWR0aCkscz10LnJvd3N8fE1hdGguZmxvb3Ioci5oZWlnaHQvby5saW5lSGVpZ2h0KTtyZXR1cm4gT2JqZWN0LmZyZWV6ZSh7ZnJhbWU6ZS5mcmFtZSx0aW1lOmUudGltZSxjb2xzOmwscm93czpzLG1ldHJpY3M6byx3aWR0aDpyLndpZHRoLGhlaWdodDpyLmhlaWdodCxzZXR0aW5nczp0LHJ1bnRpbWU6T2JqZWN0LmZyZWV6ZSh7Y3ljbGU6ZS5jeWNsZSxmcHM6bi5mcHN9KX0pfWZ1bmN0aW9uIHkoZSl7ZS5zdHlsZS51c2VyU2VsZWN0PSJub25lIixlLnN0eWxlLndlYmtpdFVzZXJTZWxlY3Q9Im5vbmUiLGUuc3R5bGUubW96VXNlclNlbGVjdD0ibm9uZSIsZS5kYXRhc2V0LnNlbGVjdGlvbkVuYWJsZWQ9ImZhbHNlIn1mdW5jdGlvbiB3KGUpe2NvbnN0IHQ9ImZhbHNlIj09IWUuZGF0YXNldC5zZWxlY3Rpb25FbmFibGVkO3R8fGZ1bmN0aW9uKGUpe2Uuc3R5bGUudXNlclNlbGVjdD0iYXV0byIsZS5zdHlsZS53ZWJraXRVc2VyU2VsZWN0PSJhdXRvIixlLnN0eWxlLm1velVzZXJTZWxlY3Q9ImF1dG8iLGUuZGF0YXNldC5zZWxlY3Rpb25FbmFibGVkPSJ0cnVlIn0oZSk7Y29uc3Qgbz1kb2N1bWVudC5jcmVhdGVSYW5nZSgpO28uc2VsZWN0Tm9kZShlKTtjb25zdCBuPXdpbmRvdy5nZXRTZWxlY3Rpb24oKTtuLnJlbW92ZUFsbFJhbmdlcygpLG4uYWRkUmFuZ2UobyksZG9jdW1lbnQuZXhlY0NvbW1hbmQoImNvcHkiKSxuLnJlbW92ZUFsbFJhbmdlcygpLHR8fHkoZSl9ZnVuY3Rpb24gYihlKXtjb25zdCB0PWdldENvbXB1dGVkU3R5bGUoZSksbz10LmdldFByb3BlcnR5VmFsdWUoImZvbnQtZmFtaWx5Iiksbj1wYXJzZUZsb2F0KHQuZ2V0UHJvcGVydHlWYWx1ZSgiZm9udC1zaXplIikpLHI9cGFyc2VGbG9hdCh0LmdldFByb3BlcnR5VmFsdWUoImxpbmUtaGVpZ2h0IikpO2xldCBsO2lmKCJDQU5WQVMiPT1lLm5vZGVOYW1lKXtjb25zdCB0PWUuZ2V0Q29udGV4dCgiMmQiKTt0LmZvbnQ9bisicHggIitvLGw9dC5tZWFzdXJlVGV4dCgiIi5wYWRFbmQoNTAsIlgiKSkud2lkdGgvNTB9ZWxzZXtjb25zdCB0PWRvY3VtZW50LmNyZWF0ZUVsZW1lbnQoInNwYW4iKTtlLmFwcGVuZENoaWxkKHQpLHQuaW5uZXJIVE1MPSIiLnBhZEVuZCg1MCwiWCIpLGw9dC5nZXRCb3VuZGluZ0NsaWVudFJlY3QoKS53aWR0aC81MCxlLnJlbW92ZUNoaWxkKHQpfXJldHVybnthc3BlY3Q6bC9yLGNlbGxXaWR0aDpsLGxpbmVIZWlnaHQ6cixmb250RmFtaWx5Om8sZm9udFNpemU6bixfdXBkYXRlOmZ1bmN0aW9uKCl7Y29uc3QgdD1iKGUpO2Zvcih2YXIgbyBpbiB0KSJudW1iZXIiIT10eXBlb2YgdFtvXSYmInN0cmluZyIhPXR5cGVvZiB0W29dfHwobVtvXT10W29dKX19fQ=="></script><script>const program={pattern: "click   me ",main(coord, context, cursor, buffer) {const t = context.time * 0.0001;const x = coord.x;const y = coord.y;const o = Math.sin(y * Math.sin(t) * 0.2 + x * 0.04 + t) * 20;const i = Math.round(Math.abs(x + y + o)) % program.pattern.length;return { char: program.pattern[i], fontWeight: "100"}}, post(context, cursor, buffer) {}};run(program, { element : document.querySelector("pre") }).then((e) => {console.log(e)}).catch((e) => {console.warn(e.message);console.log(e.error)});  let playing=false</script>  <audio src="" id="song1" volume="0.1" style="display: none;" loop="true"></audio><audio src="" id="song2" volume="0.1" style="display: none;" loop="true"></audio><script>const songs = [song1, song2];const tracks = location.hash.slice(1).split("#");const betterQuality = ["", ""];for(let i =0;i<songs.length;i++) songs[i].src = (navigator.onLine && betterQuality[i]) || tracks[i];</script>';
        /*
<svg onclick=\'(()=>{const elms=[this.getElementById("play"),this.getElementById("stop")];if(playing){try{song1.pause()}catch(e){};try{song2.pause()}catch(e){};elms[0].style.opacity=1;elms[1].style.opacity=0;playing = false}else{try{song1.play()}catch(e){};try{song2.play()}catch(e){};elms[0].style.opacity=0;elms[1].style.opacity=1;playing = true}})()\' style="cursor: pointer;position: absolute;top: 260px;left: 360px;z-index: 100;" width="32px" height="32px" viewBox="0 0 32 32"><circle cx="16" cy="16" r="16" fill="#f0f0f0" /><polygon id="stop" style="opacity:0;" points="10,10 22,10, 22,22 10,22" fill="" /><polygon id="play" points="10,7 10,25 25,15" fill="" /></svg>
*/

    string[4] memory filters = [
        'ffffff',
        '173%22%20cy%3D%22129%22%20r%3D%22120px%22%20fill%3D%22%23ff0000',
        '353%22%20cy%3D%22157%22%20r%3D%22120px%22%20fill%3D%22%2300ff00',
        '237%22%20cy%3D%22314%22%20r%3D%22100px%22%20fill%3D%22%230000ff'
    ];

        string memory uniswap = string(
            abi.encodePacked(
                '<svg width="500" height="500" viewBox="0 0 290 290"> <defs> <style> @import url("https://gateway.pinata.cloud/ipfs/QmRodGNTG8Jex8nQQwufuNi4Brb4Cqy16YBJ3CKqBYfQKP/DM_Mono.css"); </style> <filter id="f1"><feImage result="p0" xlink:href="data:image/svg+xml;binary,%3Csvg%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%3Crect%20width%3D%22290px%22%20height%3D%22290px%22%20fill%3D%22%23',
                filters[0],
                '%22%2F%3E%3C%2Fsvg%3E"> </feImage> <feImage result="p1" xlink:href="data:image/svg+xml;binary,%3Csvg%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%3E%3Ccircle%20cx%3D%22',
                filters[1],
                '%22%2F%3E%3C%2Fsvg%3E"> </feImage> <feImage result="p2" xlink:href="data:image/svg+xml;binary,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%3E%3Ccircle%20cx%3D%22',
                filters[2],
                '%22%2F%3E%3C%2Fsvg%3E"> </feImage> <feImage result="p3" xlink:href="data:image/svg+xml;binary,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22290%22%20height%3D%22290%22%20viewBox%3D%220%200%20290%20290%22%3E%3Ccircle%20cx%3D%22',
                filters[3],
                '%22%2F%3E%3C%2Fsvg%3E"> </feImage><feBlend mode="overlay" in="p0" in2="p1"></feBlend> <feBlend mode="exclusion" in2="p2"></feBlend> <feBlend mode="overlay" in2="p3" result="blendOut"></feBlend> <feGaussianBlur in="blendOut" stdDeviation="42"></feGaussianBlur> </filter> <clipPath id="corners"> <rect width="290" height="290" rx="42" ry="42"></rect> </clipPath> <path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V250 A28 28 0 0 1 250 278 H40 A28 28 0 0 1 12 250 V40 A28 28 0 0 1 40 12 z"> </path> <path id="minimap" d="M234 444C234 457.949 242.21 463 253 463"></path> <filter id="top-region-blur"> <feGaussianBlur in="SourceGraphic" stdDeviation="24"></feGaussianBlur> </filter> <linearGradient id="grad-up" x1="1" x2="0" y1="1" y2="0"> <stop offset="0.0" stop-color="white" stop-opacity="1"></stop> <stop offset=".9" stop-color="white" stop-opacity="0"></stop> </linearGradient> <linearGradient id="grad-down" x1="0" x2="1" y1="0" y2="1"> <stop offset="0.0" stop-color="white" stop-opacity="1"></stop> <stop offset="0.9" stop-color="white" stop-opacity="0"></stop> </linearGradient> <mask id="fade-up" maskContentUnits="objectBoundingBox"> <rect width="1" height="1" fill="url(#grad-up)"></rect> </mask> <mask id="fade-down" maskContentUnits="objectBoundingBox"> <rect width="1" height="1" fill="url(#grad-down)"></rect> </mask> <mask id="none" maskContentUnits="objectBoundingBox"> <rect width="1" height="1" fill="white"></rect> </mask> <linearGradient id="grad-symbol"> <stop offset="0.7" stop-color="white" stop-opacity="1"></stop> <stop offset=".95" stop-color="white" stop-opacity="0"></stop> </linearGradient> <mask id="fade-symbol" maskContentUnits="userSpaceOnUse"> <rect width="290px" height="200px" fill="url(#grad-symbol)"></rect> </mask> </defs> <g clip-path="url(#corners)"> <rect fill="7c2e0e" x="0px" y="0px" width="290px" height="290px"></rect> <rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="290px"></rect> <g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;"> <rect fill="none" x="0px" y="0px" width="290px" height="290px"></rect> <ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#000" opacity="0.85"></ellipse> </g> <rect x="0" y="0" width="290" height="290" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"> </rect> </g> <text text-rendering="optimizeSpeed"> <textPath startOffset="-100%" fill="white" font-family="\'Courier New\', monospace" font-size="9px" xlink:href="#text-path-a"> Never gonna give you up Never gonna let you down Never gonna run around and desert you <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> <textPath startOffset="0%" fill="white" font-family="\'Courier New\', monospace" font-size="9px" xlink:href="#text-path-a"> Never gonna give you up Never gonna let you down Never gonna run around and desert you <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> <textPath startOffset="50%" fill="white" font-family="\'Courier New\', monospace" font-size="9px" xlink:href="#text-path-a">  Never gonna make you cry Never gonna say goodbye Never gonna tell a lie and hurt you<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> <textPath startOffset="-50%" fill="white" font-family="\'Courier New\', monospace" font-size="9px" xlink:href="#text-path-a"> Never gonna make you cry Never gonna say goodbye Never gonna tell a lie and hurt you <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"></animate> </textPath> </text> <rect x="16" y="16" width="258" height="258" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)"> </rect> <path opacity="0.6" style="transform:translate(226px, 226px) scale(0.1)" id="Selection" fill="white" d="M 146.00,64.00 C 153.56,65.52 160.73,67.80 168.00,70.34 171.38,71.53 176.09,73.24 178.26,76.21 180.53,79.32 180.99,89.94 181.00,94.00 181.00,94.00 181.00,162.00 181.00,162.00 181.00,162.00 180.00,177.00 180.00,177.00 180.00,177.00 180.00,206.00 180.00,206.00 180.00,206.00 178.96,223.00 178.96,223.00 178.96,223.00 178.96,239.00 178.96,239.00 178.96,239.00 178.00,249.00 178.00,249.00 177.95,253.95 177.94,265.83 175.83,270.00 172.97,275.62 162.77,281.04 157.00,283.40 138.16,291.09 122.85,291.23 103.00,291.00 86.28,290.80 51.09,282.65 34.00,278.37 28.20,276.92 11.05,272.45 7.31,268.61 4.73,265.96 4.48,261.52 4.00,258.00 4.00,258.00 1.58,236.00 1.58,236.00 1.58,236.00 0.91,224.00 0.91,224.00 0.91,224.00 0.00,212.00 0.00,212.00 0.00,212.00 0.00,147.00 0.00,147.00 0.00,147.00 1.00,132.00 1.00,132.00 1.00,132.00 3.91,88.00 3.91,88.00 4.19,84.21 4.47,73.25 6.74,70.63 9.03,67.98 22.09,62.96 26.00,61.40 34.98,57.81 60.95,50.19 70.00,50.18 70.00,50.18 88.00,52.59 88.00,52.59 88.00,52.59 115.00,57.20 115.00,57.20 117.47,57.67 123.43,59.14 125.57,57.89 128.38,56.25 130.28,45.40 131.13,42.00 131.13,42.00 136.58,20.00 136.58,20.00 138.28,12.35 139.13,5.41 147.00,1.45 150.40,-0.25 154.30,-0.04 158.00,0.00 165.96,0.11 172.77,4.01 180.00,6.99 180.00,6.99 216.00,22.22 216.00,22.22 223.21,25.40 233.61,27.26 228.91,38.00 224.21,48.76 216.65,43.52 209.00,40.14 209.00,40.14 174.00,24.70 174.00,24.70 171.62,23.62 162.67,19.02 160.59,19.58 156.57,20.66 155.23,27.54 154.37,31.00 154.37,31.00 146.00,64.00 146.00,64.00 Z M 124.00,69.00 C 124.00,69.00 72.00,60.32 72.00,60.32 67.35,59.97 54.19,62.85 50.00,65.00 50.00,65.00 112.00,79.87 112.00,79.87 117.41,81.23 133.47,85.93 138.00,85.45 142.55,84.96 157.13,80.37 161.00,78.00 161.00,78.00 146.14,74.61 146.14,74.61 142.67,75.03 143.18,78.25 138.94,80.55 134.35,83.03 125.51,81.82 123.46,76.56 122.80,74.88 123.73,70.92 124.00,69.00 Z M 124.00,88.00 C 124.00,88.00 59.00,72.35 59.00,72.35 45.30,69.20 36.90,64.66 24.00,74.00 24.00,74.00 95.00,88.58 95.00,88.58 104.21,90.24 115.96,94.45 124.00,88.00 Z M 109.00,102.00 C 109.00,102.00 44.00,88.58 44.00,88.58 44.00,88.58 14.00,82.00 14.00,82.00 14.00,82.00 11.00,130.00 11.00,130.00 11.00,130.00 10.00,147.00 10.00,147.00 10.00,147.00 10.00,213.00 10.00,213.00 10.00,213.00 10.91,223.00 10.91,223.00 10.91,223.00 12.72,247.00 12.72,247.00 13.11,250.03 13.71,258.36 15.17,260.61 17.65,264.42 34.07,268.10 39.00,269.37 39.00,269.37 62.00,274.65 62.00,274.65 65.99,275.55 73.09,277.25 77.00,276.66 86.29,275.25 93.68,266.96 97.73,259.00 105.49,243.74 109.97,213.23 110.00,196.00 110.00,196.00 110.00,136.00 110.00,136.00 110.00,136.00 109.00,121.00 109.00,121.00 109.00,121.00 109.00,102.00 109.00,102.00 Z M 165.00,88.00 C 165.00,88.00 151.00,93.00 151.00,93.00 156.84,99.26 153.13,108.76 156.00,116.00 156.00,116.00 165.00,88.00 165.00,88.00 Z M 150.00,93.00 C 144.50,95.21 145.98,99.76 146.00,105.00 146.00,105.00 147.00,126.00 147.00,126.00 152.14,125.14 152.71,123.91 154.00,119.00 152.15,118.54 151.21,118.63 150.02,116.77 148.78,114.83 149.03,111.26 149.00,109.00 148.89,101.12 146.78,100.63 150.00,93.00 Z M 138.00,97.00 C 138.00,97.00 125.00,100.00 125.00,100.00 127.71,105.74 132.89,110.34 138.00,114.00 138.00,114.00 138.00,97.00 138.00,97.00 Z M 170.00,101.00 C 167.61,104.89 163.46,117.04 161.69,122.00 160.68,124.85 159.42,129.42 157.35,131.57 154.35,134.70 144.63,134.97 141.31,132.26 138.72,130.15 139.57,127.81 136.69,124.00 133.67,120.01 121.17,107.98 117.00,105.00 117.00,105.00 117.00,147.00 117.00,147.00 117.00,147.00 118.00,164.00 118.00,164.00 118.00,164.00 118.00,240.00 118.00,240.00 118.00,240.00 119.00,255.00 119.00,255.00 119.00,255.00 119.00,281.00 119.00,281.00 130.12,280.97 143.79,277.97 154.00,273.57 157.41,272.10 163.91,268.87 165.83,265.68 167.04,263.66 167.98,249.10 168.04,246.00 168.04,246.00 168.04,234.00 168.04,234.00 168.04,234.00 169.00,222.00 169.00,222.00 169.00,222.00 169.00,203.00 169.00,203.00 169.00,203.00 170.00,187.00 170.00,187.00 170.00,187.00 170.00,138.00 170.00,138.00 170.00,138.00 170.96,124.00 170.96,124.00 170.96,124.00 170.96,110.00 170.96,110.00 170.96,110.00 170.00,101.00 170.00,101.00 Z M 61.00,170.00 C 61.00,170.00 26.00,166.83 26.00,166.83 23.09,166.54 14.42,166.63 16.17,161.94 17.15,159.32 26.51,149.59 28.91,147.00 28.91,147.00 57.72,115.00 57.72,115.00 62.04,110.08 67.30,102.14 74.00,101.00 74.00,101.00 67.30,119.00 67.30,119.00 67.30,119.00 57.00,142.00 57.00,142.00 57.00,142.00 87.00,142.00 87.00,142.00 87.00,142.00 105.00,143.00 105.00,143.00 103.03,149.25 89.97,169.20 85.68,176.00 85.68,176.00 52.95,229.00 52.95,229.00 52.95,229.00 41.20,248.00 41.20,248.00 38.68,252.12 38.18,254.67 33.00,254.00 33.00,254.00 46.33,213.00 46.33,213.00 46.33,213.00 61.00,170.00 61.00,170.00 Z" width="200" height="200"></path> <path fill="#ffffff" transform="translate(50, 50) scale(8)" d="M12 0L1.608 6v12L12 24l10.392-6V6zm-1.073 1.445h.001a1.8 1.8 0 0 0 2.138 0l7.534 4.35a1.794 1.794 0 0 0 0 .403l-7.535 4.35a1.8 1.8 0 0 0-2.137 0l-7.536-4.35a1.795 1.795 0 0 0 0-.402zM21.324 7.4c.109.08.226.147.349.201v8.7a1.8 1.8 0 0 0-1.069 1.852l-7.535 4.35a1.8 1.8 0 0 0-.349-.2l-.009-8.653a1.8 1.8 0 0 0 1.07-1.851zm-18.648.048l7.535 4.35a1.8 1.8 0 0 0 1.069 1.852v8.7c-.124.054-.24.122-.349.202l-7.535-4.35a1.8 1.8 0 0 0-1.069-1.852v-8.7a1.85 1.85 0 0 0 .35-.202z"/><g style="transform:translate(29px, 244px)"> <rect width="54px" height="17.3333px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)"></rect><text x="8px" y="11.333px" font-family="\'Courier New\', monospace" font-size="8px" fill="white">Click me</text></g> </svg>'
            )
        );
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"name": "RickRolled #1", "description": "Never Gonna Give You Up is the debut single recorded by English singer and songwriter Rick Astley, released on 27 July 1987.", "image": "https://cloudflare-ipfs.com/ipfs/QmdmPHWQBzV24GvbwCszm2AnWetBENeBP2UStuETsyAp1C", "audio": "https://cloudflare-ipfs.com/ipfs/QmWmmmrQB3iFXHPNStyL7GvgZcifGz3JrzcFbSLQzyevjn", "animation_url": "',
                            'data:text/html;base64,',
                            Base64.encode(abi.encodePacked(uniswap, html)),
                            '#',
                            '#',
                            getAudioAssetBase64(0),
                            '", "external_url": "https://en.wikipedia.org/wiki/Rick_Astley", "attributes": [{"trait_type": "Chord Progression", "value": "2"}, {"trait_type": "First Melody", "value": "2"}, {"trait_type": "Second Melody", "value": "1"}, {"trait_type": "Third Melody", "value": "3"}, {"trait_type": "Drums", "value": "3"}], "composer": "Shaw Avery @ShawAverySongs"}'
                        )
                    )
                )
            );
    }

    function getAudioAssetBase64(uint16 _assetId) public view override returns (string memory) {
        return string(abi.encodePacked('data:audio/mp3;base64,', Base64.encode(assets.getAssetBytes(_assetId))));
    }
}
