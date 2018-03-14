using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TramplerSpawner : MonoBehaviour {

    [Range(0, 100)]
    public int numBots = 0; 
    public GameObject tramplerPrefab;

    private GrassPhysics grassPhysics;

    void Awake() {
        grassPhysics = GetComponent<GrassPhysics>();
        for(int i = 0; i < numBots; i++) {
            GameObject tramplerGo = Instantiate(tramplerPrefab, TramplerBot.GetRandomPoint() + new Vector3(0,30,0), Quaternion.identity);
            grassPhysics.tramplers.Add(tramplerGo.transform); 
        }
    }


}
