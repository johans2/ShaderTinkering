using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TramplerBot : MonoBehaviour {

    public float moveSpeed;

    CharacterController ctrl;

    Vector3 target;

    IEnumerator Start()
    {
        ctrl = GetComponent<CharacterController>();
        ctrl.enabled = false;
        yield return new WaitForEndOfFrame();
        ctrl.enabled = true;
        target = GetRandomPoint();
    }

    void Update()
    {
        if (!ctrl.enabled)
        {
            return;
        }

        if (Vector2.Distance(new Vector2(target.x, target.z), new Vector2(transform.position.x, transform.position.z)) < 1f)
        {
            target = GetRandomPoint();
        }

        Vector3 moveDir = Vector3.Normalize( target - transform.position) * moveSpeed;
        
        moveDir.y = -20f;

        ctrl.Move(moveDir * Time.deltaTime);
    }


    Vector3 GetRandomPoint() {
        return new Vector3(Random.Range(-40f, 40f), 0, Random.Range(-40f, 40f));
    }
}
