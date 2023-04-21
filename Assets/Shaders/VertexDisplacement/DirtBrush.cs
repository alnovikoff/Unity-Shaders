using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DirtBrush : MonoBehaviour
{
    public CustomRenderTexture customRenderTex;
    private Camera mainCamera;
    public Material material;

    public GameObject[] tires;
    private int tireIndex;

    private static readonly int DrawPosition = Shader.PropertyToID("_DrawPosition");
    private static readonly int DrawAngle = Shader.PropertyToID("_DrawAngle");

    void Start()
    {
        customRenderTex.Initialize();
        mainCamera = Camera.main;
    }

    void Update()
    {
        //MouseBrush();

        DrawWithTires();
    }

    private void DrawWithMouse()
    {
        if (Input.GetMouseButton(0))
        {
            Ray ray = mainCamera.ScreenPointToRay(Input.mousePosition);

            if (Physics.Raycast(ray, out RaycastHit hit))
            {
                Vector2 hitTextureCoord = hit.textureCoord;

                material.SetVector(DrawPosition, hitTextureCoord);
                material.SetFloat(DrawAngle, 45 * Mathf.Deg2Rad);
            }
        }
    }

    private void DrawWithTires()
    {
        GameObject tire = tires[tireIndex++ % tires.Length];

        Ray ray = new Ray(tire.transform.position, Vector3.down);
        if (Physics.Raycast(ray, out RaycastHit hit))
        {
            Vector2 hitTextureCoord = hit.textureCoord;
            float angle = tire.transform.rotation.eulerAngles.y;

            material.SetVector(DrawPosition, hitTextureCoord);
            material.SetFloat(DrawAngle, angle * Mathf.Deg2Rad);
        }
    }
}
