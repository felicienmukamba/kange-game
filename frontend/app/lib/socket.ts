import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

export const createStompClient = (onConnect: (client: Client) => void, onDisconnect: () => void) => {
  const socket = new SockJS('http://localhost:8080/ws');
  const client = new Client({
    webSocketFactory: () => socket,
    debug: (str) => {
      console.log(str);
    },
    reconnectDelay: 5000,
    heartbeatIncoming: 4000,
    heartbeatOutgoing: 4000,
  });

  client.onConnect = () => onConnect(client);
  client.onDisconnect = onDisconnect;

  return client;
};
