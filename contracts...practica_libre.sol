// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0;

//NOMBRE PARTICIPANTES                                                         // DIRECCION
//ELVIS  0x456c766973000000000000000000000000000000000000000000000000000000    0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
//CHRISTIAN 0x43687269737469616e0000000000000000000000000000000000000000000000 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
//JOSE 0x4a6f736500000000000000000000000000000000000000000000000000000000      0x617F2E2fD72FD9D5503197092aC168c91465E7f2
//MIGUEL 0x4d696775656c0000000000000000000000000000000000000000000000000000    0x17F6AD8Ef982297579C203069C1DbfFE4348c372

//VOTANTES
//VOTO 1: 0x6110Af36D0E864d04Cf59f983b639FFCE4B91ce4
//VOTO 2: 0x1097CE9FF3ED3adEb8628C6a24c0c2375fdEAa8e
//VOTO 3: 0xdD870fA1b7C4700F2BD7f44238821C26f7392148
//VOTO 4: 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C

//PRESIDENTE 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

contract VotacionDelegada {

    struct Votante { 
        //se declara un tipo complejo que se utilizara para
        //identificar a un votante
        uint peso; //peso del votante acumulado por delegacion
        bool votoPrevio;  // Si es True, el votante ya ha votado previamente
        address delegado; // participante al que se delego
        uint voto;   // indice del participante votado
    }

    struct Participante { //tipo para unico participante
        bytes32 nombre;   // nombre del participante
        uint contadorVotos; // cuenta de los votos adquiridos
    }

    address public presidente; //Presdiente encargado de dar permiso de voto

    mapping(address => Votante) public votantes;
    //Esto es una variable de estado que guardara un struct Votante 
    //para cada una de las direcciones

    Participante[] public participantes;

    //Se crea una nueva eleccion para elegir uno de los nombres de participantes
    constructor(bytes32[] memory nombresParticipantes) {
        presidente = msg.sender;
        votantes[presidente].peso = 1;
        for (uint i = 0; i < nombresParticipantes.length; i++) {
            participantes.push(Participante({
                nombre: nombresParticipantes[i],
                contadorVotos: 0
            }));
        }
    }
    

    //Le da al votante el derecho a votar en esta eleccion
    //Solo puede ser llamado por el presidente
    function derechoVoto(address votante) public {
        require(
            msg.sender == presidente,
            "Solo el presiedente puede dar el derecho a voto"
        );
        require(
            !votantes[votante].votoPrevio,
            "El votante ya voto"
        );
        require(votantes[votante].peso == 0);
        votantes[votante].peso = 1;
    }

    // Se delega el voto del votador a la direccion la cuenta especificada
    function delegado(address direccion) public {
        Votante storage sender = votantes[msg.sender];
        require(!sender.votoPrevio, "Ya ha votado previamente");
        require(direccion != msg.sender, "No se permite delegacion propia");


        while (votantes[direccion].delegado != address(0)) {
            direccion = votantes[direccion].delegado;
            // Se encuentra un loop en la delegacion,lo cual no esta permitido
            require(direccion != msg.sender, "Se encuentra loop en la delegacion");
        }
        sender.votoPrevio = true;
        sender.delegado = direccion;
        Votante storage delegado_ = votantes[direccion];

        //Los votantes no pueden delegar a cuentas que no pueden votar
        if (delegado_.votoPrevio) {
            // Si el delegado ya voto se le añado al numero de votos
            participantes[delegado_.voto].contadorVotos += sender.peso;
        } else {
            //Si el delegado no ha votado aun, se le añade al peso
            delegado_.peso += sender.peso;
        }
    }

    // Dar voto (junto con los votos delegados) al participante
    function votar(uint participante) public {
        Votante storage sender = votantes[msg.sender];
        require(sender.peso != 0, "No tiene el derecho de votar");
        require(!sender.votoPrevio, "Ya ha votado previamente");
        sender.votoPrevio = true;
        sender.voto = participante;
        participantes[participante].contadorVotos += sender.peso;
    }

    //Se contabilizan los votos y se elige el ganador
    function participanteGanador() public view
            returns (uint participanteGanador_)
    {
        uint contadorVotosGanador = 0;

        for (uint p = 0; p < participantes.length; p++) {
            if (participantes[p].contadorVotos > contadorVotosGanador) {
                contadorVotosGanador = participantes[p].contadorVotos;
                participanteGanador_ = p;
            }
        }
    }


    // Se extrae el indice del ganador para extraer 
    // su nombre del array de participantes
    function ganador_() public view
            returns (bytes32 ganador)        
    {
        ganador= participantes[participanteGanador()].nombre;
    }
}

