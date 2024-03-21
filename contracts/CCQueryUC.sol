//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CCQueryUC is UniversalChanIbcApp {
    // app specific state
    uint64 private counter;
    mapping(uint64 => address) public counterMap;
    mapping(address => bool) public addressMap;

    event LogQuery(address indexed caller, string query, uint64 counter);
    event LogAcknowledgement(string message);

    string private constant SECRET_MESSAGE = "Polymer is not a bridge: ";
    string private constant LIMIT_MESSAGE = "Sorry, but the 500 limit has been reached, stay tuned for challenge 4";

    constructor(address _middleware) UniversalChanIbcApp(_middleware) {}

    // app specific logic
    function resetCounter() internal {
        counter = 0;
    }

    function increment() internal {
        counter++;
    }

    function getCounter() internal view returns (uint64) {
        return counter;
    }

    // IBC logic

    /**
 * @dev Sends a packet with the caller's address over the universal channel.
 * @param destPortAddr The address of the destination application.
 * @param channelId The ID of the channel to send the packet to.
 * @param timeoutSeconds The timeout in seconds (relative).
 */
function sendUniversalPacket(address destPortAddr, bytes32 channelId, uint64 timeoutSeconds) external {
    // 1. Encode the caller's address and the query string into a payload
    bytes memory payload = abi.encode(msg.sender, "crossChainQuery");

    // 2. Set the timeout timestamp at 10h from now
    uint64 timeoutTimestamp = uint64(block.timestamp) + 10 hours;

    // 3. Call the IbcUniversalPacketSender to send the packet
    ibcUniversalPacketSender.sendUniversalPacket(
        destPortAddr,
        channelId,
        payload,
        timeoutTimestamp,
        timeoutSeconds
    );
}

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the packet was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     */
    function onRecvUniversalPacket(bytes32 channelId, UniversalPacket calldata packet)
        external
        override
        onlyIbcMw
        returns (AckPacket memory ackPacket)
    {
        // You can leave the following function empty
        // This contract will need to be sending and acknowledging packets and not receiving them to complete the challenge
        // The reference implemention of onRecvUniversalPacket on the base contract you will be calling is below

        /*
        recvedPackets.push(UcPacketWithChannel(channelId, packet));
        uint64 _counter = getCounter();

        (address _caller, string memory _query) = abi.decode(packet.appData, (address, string));

        require(!addressMap[_caller], "Address already queried");
        if (_counter >= 500) {
            return AckPacket(true, abi.encode(LIMIT_MESSAGE));
        }

        if (keccak256(bytes(_query)) == keccak256(bytes("crossChainQuery"))) {
            increment();
            addressMap[_caller] = true;
            uint64 newCounter = getCounter();
            emit LogQuery(_caller, _query, newCounter);

            string memory counterString = Strings.toString(newCounter);

            string memory _ackData = string(abi.encodePacked(SECRET_MESSAGE, counterString));

            return AckPacket(true, abi.encode(_ackData));
        }
        */
    }

    /**
 * @dev Packet lifecycle callback that implements packet acknowledgment logic.
 * @param channelId the ID of the channel (locally) the ack was received on.
 * @param packet the Universal packet encoded by the source and relayed by the relayer.
 * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
 */
function onUniversalAcknowledgement(bytes32 channelId, UniversalPacket memory packet, AckPacket calldata ack)
    external
    override
    onlyIbcMw
{
    // 1. Decode the message from the ack.ackData
    string memory message = abi.decode(ack.ackData, (string));

    // 2. Emit the LogAcknowledgement event with the decoded message
    emit LogAcknowledgement(message);
}

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     *
     * @param channelId the ID of the channel (locally) the timeout was submitted on.
     * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // do logic
    }
}
