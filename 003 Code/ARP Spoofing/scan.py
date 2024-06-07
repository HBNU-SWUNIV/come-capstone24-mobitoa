# ARP Spoofing 탐지

from scapy.all import ARP, sniff
from collections import deque
import time

def handle_arp_packet(pkt):
    global arp_cache, tp_mac, timer_start, rt_list
    
    if pkt.haslayer(ARP) and pkt[ARP].op == 2: 
        rsp_mac = pkt[ARP].hwsrc
        ot = time.time() - timer_start
        tp_mac.append((rsp_mac, ot))
        
        if len(tp_mac) > 1:
            # MAC 주소 비교
            if tp_mac[-1][0] != tp_mac[-2][0]: 
                timer_start = 0 # Timer 종료
            else:
                rt = abs(tp_mac[-1][1] - tp_mac[-2][1])
                rt_list.append(rt)

                if len(rt_list) > 1: # Reach Time이 2개 이상인 경우
                    rt_avg = sum(rt_list) / len(rt_list) # Reach Time의 평균 계산
                    rt_percent = (rt / rt_avg) * 100 # RT를 %로 변환

                    if abs(rt_percent - 100) > 1: # Error Range가 1% 이상인 경우
                        timer_start = 0 # Timer 종료
                        print("[!]")
                        print(" |-- ARP Poisoning Detected")
                        print(" |-- target IP:", pkt[ARP].psrc)
                        print(" |-- Attacker MAC:", pkt[ARP].hwsrc)
                        print()
                    else:
                        print("[+]")
                        print(" |-- Normal ARP Reply Packet")
                        print(" |-- target IP:", pkt[ARP].psrc)
                        print(" |-- Attacker MAC:", pkt[ARP].hwsrc)
                        print()

def start_arp_sniffing():
    sniff(prn=handle_arp_packet, filter="arp", store=0)

def stop_arp_sniffing():
    sniff_thread.terminate()

if __name__ == "__main__":
    arp_cache = {}
    rt_list = []
    tp_mac = deque(maxlen=2)
    timer_start = 0

    start_arp_sniffing()
