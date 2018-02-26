using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Trampler : MonoBehaviour {

    public float moveSpeed;

    CharacterController ctrl;

	void Start () {
        ctrl = GetComponent<CharacterController>();
	}
	
	void Update () {
        Vector3 moveDir = new Vector3();

        if(Input.GetKey(KeyCode.UpArrow) ) {
            moveDir.z = moveSpeed;
        }
        if(Input.GetKey(KeyCode.DownArrow)) {
            moveDir.z = -moveSpeed;
        }
        if(Input.GetKey(KeyCode.RightArrow)) {
            moveDir.x = moveSpeed;
        }
        if(Input.GetKey(KeyCode.LeftArrow)) {
            moveDir.x = -moveSpeed;
        }

        moveDir.y = -20f;

        ctrl.Move(moveDir * Time.deltaTime);
    }
}
