using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Trampler : MonoBehaviour {

    public float moveSpeed;
    public GameObject character;

    CharacterController ctrl;
    Animator anim;

	IEnumerator Start () {
        ctrl = GetComponent<CharacterController>();
        ctrl.enabled = false;
        yield return new WaitForEndOfFrame();
        ctrl.enabled = true;
        anim = GetComponentInChildren<Animator>();
	}
	
	void Update () {
        if (!ctrl.enabled) {
            return;
        }

        Vector3 moveDir = new Vector3();
        Vector3 rotation = Vector3.zero;
        float speed = 0;

        if(Input.GetKey(KeyCode.UpArrow) ) {
            moveDir = transform.forward * moveSpeed;
            speed = 1;
        }
        if(Input.GetKey(KeyCode.DownArrow)) {
            moveDir = transform.forward * -moveSpeed;
            speed = 1;
        }
        if(Input.GetKey(KeyCode.RightArrow)) {
            rotation = new Vector3(0, 2.5f, 0);
        }
        if(Input.GetKey(KeyCode.LeftArrow)) {
            rotation = new Vector3(0, -2.5f, 0);
        }

        moveDir.y = -20f;
        anim.SetFloat("Speed", speed);
        ctrl.transform.Rotate(rotation);
        ctrl.Move(moveDir * Time.deltaTime);
    }
}
