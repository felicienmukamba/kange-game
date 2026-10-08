import { Client } from '@stomp/stompjs';
import SockJS from 'sockjs-client';

export const WS_URL = process.env.NEXT_PUBLIC_WS_URL ?? 'http://localhost:8080/ws';

/** Creates a STOMP client over SockJS, authenticated with the user's JWT. */
export const createStompClient = (
  token: string,
  onConnect: (client: Client) => void,
  onDisconnect: () => void
) => {
  // SockJS expects an http(s) URL; accept ws(s) for convenience
  const url = WS_URL.replace(/^ws(s?):\/\//, 'http$1://');
  const client = new Client({
    webSocketFactory: () => new SockJS(url),
    connectHeaders: { Authorization: `Bearer ${token}` },
    reconnectDelay: 5000,
    heartbeatIncoming: 10000,
    heartbeatOutgoing: 10000,
  });

  client.onConnect = () => onConnect(client);
  client.onWebSocketClose = onDisconnect;
  client.onStompError = (frame) => console.error('STOMP error:', frame.headers['message']);

  return client;
};
