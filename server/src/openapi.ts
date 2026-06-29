import fastifySwagger from '@fastify/swagger';
import fastifySwaggerUi from '@fastify/swagger-ui';
import { type FastifyInstance } from 'fastify';

const jsonContent = (schema: unknown) => ({
  'application/json': {
    schema
  }
});

const errorContent = jsonContent({ $ref: '#/components/schemas/ErrorResponse' });

const errorHeaders = {
  'x-request-id': {
    description: 'Request correlation ID.',
    schema: { type: 'string' }
  },
  'x-error-id': {
    description: 'Support reference for this error.',
    schema: { type: 'string' }
  }
};

const errorResponse = (description: string) => ({
  description,
  headers: errorHeaders,
  content: errorContent
});

export const openApiDocument = {
  openapi: '3.0.3',
  info: {
    title: 'All Of Me Cloud Save API',
    version: '0.1.0',
    description:
      'REST API for optional encrypted All Of Me cloud-save restore points. ' +
      'The current device remains the source of truth; the server stores ' +
      'encrypted packages and never decrypts app data.'
  },
  servers: [
    {
      url: 'https://api.allofmeapp.com',
      description: 'Production'
    },
    {
      url: 'http://127.0.0.1:3000',
      description: 'Local development'
    }
  ],
  tags: [
    {
      name: 'System',
      description: 'Process health and operational checks.'
    },
    {
      name: 'Devices',
      description: 'Cloud Save device registration and one-time link codes.'
    },
    {
      name: 'Saves',
      description: 'Encrypted Cloud Save upload and restore endpoints.'
    }
  ],
  paths: {
    '/healthz': {
      get: {
        tags: ['System'],
        summary: 'Health check',
        operationId: 'getHealth',
        responses: {
          200: {
            description: 'API process is healthy.',
            content: jsonContent({ $ref: '#/components/schemas/HealthResponse' })
          }
        }
      }
    },
    '/v1/devices/register': {
      post: {
        tags: ['Devices'],
        summary: 'Register first device',
        operationId: 'registerDevice',
        requestBody: {
          required: false,
          content: jsonContent({
            $ref: '#/components/schemas/RegisterDeviceRequest'
          })
        },
        responses: {
          201: {
            description: 'Device registered. Store the returned bearer token once.',
            content: jsonContent({
              $ref: '#/components/schemas/DeviceRegistration'
            })
          },
          400: { $ref: '#/components/responses/BadRequest' },
          429: { $ref: '#/components/responses/TooManyRequests' },
          500: { $ref: '#/components/responses/ServerError' }
        }
      }
    },
    '/v1/devices/link-codes': {
      post: {
        tags: ['Devices'],
        summary: 'Create a device link code',
        operationId: 'createDeviceLinkCode',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: false,
          content: jsonContent({ $ref: '#/components/schemas/EmptyObject' })
        },
        responses: {
          201: {
            description: 'One-time code created for another device.',
            content: jsonContent({ $ref: '#/components/schemas/DeviceLinkCode' })
          },
          401: { $ref: '#/components/responses/Unauthorized' },
          429: { $ref: '#/components/responses/TooManyRequests' },
          500: { $ref: '#/components/responses/ServerError' }
        }
      }
    },
    '/v1/devices/link': {
      post: {
        tags: ['Devices'],
        summary: 'Redeem a device link code',
        operationId: 'redeemDeviceLinkCode',
        requestBody: {
          required: true,
          content: jsonContent({
            $ref: '#/components/schemas/RedeemDeviceLinkCodeRequest'
          })
        },
        responses: {
          201: {
            description: 'New device registered in the existing account.',
            content: jsonContent({
              $ref: '#/components/schemas/DeviceRegistration'
            })
          },
          400: { $ref: '#/components/responses/BadRequest' },
          401: { $ref: '#/components/responses/Unauthorized' },
          429: { $ref: '#/components/responses/TooManyRequests' },
          500: { $ref: '#/components/responses/ServerError' }
        }
      }
    },
    '/v1/saves': {
      get: {
        tags: ['Saves'],
        summary: 'List cloud-save versions',
        operationId: 'listCloudSaveVersions',
        security: [{ bearerAuth: [] }],
        responses: {
          200: {
            description: 'Newest-first save metadata for this account.',
            content: jsonContent({
              type: 'array',
              items: { $ref: '#/components/schemas/CloudSaveMetadata' }
            })
          },
          401: { $ref: '#/components/responses/Unauthorized' },
          429: { $ref: '#/components/responses/TooManyRequests' },
          500: { $ref: '#/components/responses/ServerError' }
        }
      },
      post: {
        tags: ['Saves'],
        summary: 'Upload an encrypted cloud save',
        operationId: 'uploadCloudSave',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: jsonContent({ $ref: '#/components/schemas/CloudSavePackage' })
        },
        responses: {
          201: {
            description: 'Cloud save stored. Response is the stored metadata.',
            content: jsonContent({
              $ref: '#/components/schemas/CloudSaveMetadata'
            })
          },
          400: { $ref: '#/components/responses/BadRequest' },
          401: { $ref: '#/components/responses/Unauthorized' },
          413: { $ref: '#/components/responses/PayloadTooLarge' },
          429: { $ref: '#/components/responses/TooManyRequests' },
          500: { $ref: '#/components/responses/ServerError' }
        }
      }
    },
    '/v1/saves/latest': {
      get: {
        tags: ['Saves'],
        summary: 'Download latest cloud save',
        operationId: 'downloadLatestCloudSave',
        security: [{ bearerAuth: [] }],
        responses: {
          200: {
            description: 'Newest encrypted CloudSavePackage for this account.',
            content: jsonContent({ $ref: '#/components/schemas/CloudSavePackage' })
          },
          401: { $ref: '#/components/responses/Unauthorized' },
          404: { $ref: '#/components/responses/NotFound' },
          429: { $ref: '#/components/responses/TooManyRequests' },
          500: { $ref: '#/components/responses/ServerError' }
        }
      }
    },
    '/v1/saves/{saveId}': {
      get: {
        tags: ['Saves'],
        summary: 'Download cloud save by ID',
        operationId: 'downloadCloudSaveById',
        security: [{ bearerAuth: [] }],
        parameters: [
          {
            name: 'saveId',
            in: 'path',
            required: true,
            description: 'Account-scoped cloud-save ID.',
            schema: { $ref: '#/components/schemas/CloudSaveId' }
          }
        ],
        responses: {
          200: {
            description: 'Encrypted CloudSavePackage for this account.',
            content: jsonContent({ $ref: '#/components/schemas/CloudSavePackage' })
          },
          400: { $ref: '#/components/responses/BadRequest' },
          401: { $ref: '#/components/responses/Unauthorized' },
          404: { $ref: '#/components/responses/NotFound' },
          429: { $ref: '#/components/responses/TooManyRequests' },
          500: { $ref: '#/components/responses/ServerError' }
        }
      }
    }
  },
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'opaque device token'
      }
    },
    schemas: {
      EmptyObject: {
        type: 'object',
        additionalProperties: false
      },
      HealthResponse: {
        type: 'object',
        additionalProperties: false,
        required: ['ok'],
        properties: {
          ok: { type: 'boolean', example: true }
        }
      },
      ErrorResponse: {
        type: 'object',
        additionalProperties: false,
        required: ['statusCode', 'error', 'message', 'errorId', 'requestId'],
        properties: {
          statusCode: { type: 'integer', example: 400 },
          error: { type: 'string', example: 'Bad Request' },
          message: {
            type: 'string',
            example: 'Cloud save package is invalid.'
          },
          errorId: {
            type: 'string',
            example: 'err_00000000-0000-0000-0000-000000000000'
          },
          requestId: {
            type: 'string',
            example: 'req_00000000-0000-0000-0000-000000000000'
          }
        }
      },
      RegisterDeviceRequest: {
        type: 'object',
        additionalProperties: false,
        properties: {
          deviceLabel: {
            type: 'string',
            minLength: 1,
            maxLength: 100,
            example: 'Miguel iPhone'
          }
        }
      },
      RedeemDeviceLinkCodeRequest: {
        type: 'object',
        additionalProperties: false,
        required: ['code'],
        properties: {
          code: {
            type: 'string',
            minLength: 1,
            maxLength: 80,
            example: 'AOM-12345-ABCDE'
          },
          deviceLabel: {
            type: 'string',
            minLength: 1,
            maxLength: 100,
            example: 'Miguel iPad'
          }
        }
      },
      DeviceRegistration: {
        type: 'object',
        additionalProperties: false,
        required: ['accountId', 'deviceId', 'token', 'tokenType'],
        properties: {
          accountId: { type: 'string', example: 'account-1782264000000-abcd' },
          deviceId: { type: 'string', example: 'device-1782264000000-abcd' },
          deviceLabel: { type: 'string', example: 'Miguel iPhone' },
          token: { type: 'string', example: 'aom_redacted' },
          tokenType: { type: 'string', enum: ['Bearer'] }
        }
      },
      DeviceLinkCode: {
        type: 'object',
        additionalProperties: false,
        required: ['code', 'expiresAt'],
        properties: {
          code: {
            type: 'string',
            pattern: '^AOM-[0-9A-F]{5}-[0-9A-F]{5}$',
            example: 'AOM-12345-ABCDE'
          },
          expiresAt: {
            type: 'string',
            format: 'date-time',
            example: '2026-06-24T12:10:00.000Z'
          }
        }
      },
      CloudSaveId: {
        type: 'string',
        minLength: 1,
        maxLength: 128,
        pattern: '^[A-Za-z0-9][A-Za-z0-9._:-]*$',
        example: 'cloud-save-1782264000000000'
      },
      CloudSaveMetadata: {
        type: 'object',
        additionalProperties: false,
        required: [
          'saveId',
          'createdAt',
          'appName',
          'snapshotSchemaVersion',
          'payloadByteCount',
          'payloadChecksum'
        ],
        properties: {
          saveId: { $ref: '#/components/schemas/CloudSaveId' },
          createdAt: {
            type: 'string',
            format: 'date-time',
            example: '2026-06-23T18:40:00.000Z'
          },
          appName: {
            type: 'string',
            minLength: 1,
            maxLength: 100,
            example: 'All Of Me'
          },
          appVersion: {
            type: 'string',
            minLength: 1,
            maxLength: 50,
            example: '1.0.0+10'
          },
          snapshotSchemaVersion: { type: 'integer', minimum: 1, example: 3 },
          deviceLabel: {
            type: 'string',
            minLength: 1,
            maxLength: 100,
            example: 'Miguel iPhone'
          },
          payloadByteCount: {
            type: 'integer',
            minimum: 1,
            example: 123456
          },
          payloadChecksum: {
            type: 'string',
            pattern: '^fnv1a32:[0-9a-f]{8}$',
            example: 'fnv1a32:1234abcd'
          }
        }
      },
      CloudSaveEncryption: {
        type: 'object',
        additionalProperties: false,
        required: [
          'algorithm',
          'keyDerivationAlgorithm',
          'keyDerivationIterations',
          'keyLengthBits',
          'keyId',
          'nonceBase64',
          'saltBase64',
          'macBase64'
        ],
        properties: {
          algorithm: { type: 'string', enum: ['xchacha20-poly1305'] },
          keyDerivationAlgorithm: {
            type: 'string',
            enum: ['pbkdf2-hmac-sha256']
          },
          keyDerivationIterations: {
            type: 'integer',
            minimum: 1,
            example: 120000
          },
          keyLengthBits: { type: 'integer', minimum: 1, example: 256 },
          keyId: {
            type: 'string',
            minLength: 1,
            maxLength: 128,
            example: 'passphrase-recovery-key-v1'
          },
          nonceBase64: {
            type: 'string',
            description: 'Canonical base64 that decodes to 24 bytes.',
            pattern: '^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$'
          },
          saltBase64: {
            type: 'string',
            description: 'Canonical base64 that decodes to 16 bytes.',
            pattern: '^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$'
          },
          macBase64: {
            type: 'string',
            description: 'Canonical base64 that decodes to 16 bytes.',
            pattern: '^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$'
          }
        }
      },
      CloudSavePayload: {
        type: 'object',
        additionalProperties: false,
        required: ['encoding', 'compression', 'encryption', 'data'],
        properties: {
          encoding: { type: 'string', enum: ['base64'] },
          compression: { type: 'string', enum: ['none'] },
          encryption: { $ref: '#/components/schemas/CloudSaveEncryption' },
          data: {
            type: 'string',
            minLength: 1,
            description: 'Canonical base64 encrypted payload bytes.',
            pattern: '^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$'
          }
        }
      },
      CloudSavePackage: {
        type: 'object',
        additionalProperties: false,
        required: ['formatVersion', 'metadata', 'payload'],
        properties: {
          formatVersion: { type: 'integer', enum: [1] },
          metadata: { $ref: '#/components/schemas/CloudSaveMetadata' },
          payload: { $ref: '#/components/schemas/CloudSavePayload' }
        }
      }
    },
    responses: {
      BadRequest: errorResponse('Request JSON, route parameter, or envelope is invalid.'),
      Unauthorized: errorResponse('Bearer token or link code is missing, invalid, expired, or reused.'),
      NotFound: errorResponse('The requested account-scoped save was not found.'),
      PayloadTooLarge: errorResponse('The decoded cloud-save payload exceeds the configured limit.'),
      TooManyRequests: {
        ...errorResponse('A rate limit was exceeded.'),
        headers: {
          ...errorHeaders,
          'retry-after': {
            description: 'Seconds to wait before retrying.',
            schema: { type: 'string' }
          }
        }
      },
      ServerError: errorResponse('Unexpected server error.')
    }
  },
  externalDocs: {
    description: 'Markdown REST contract and operational notes.',
    url: 'https://github.com/KopitarFan/AllOfMe/blob/main/docs/server-rest-api.md'
  }
};

export async function registerOpenApiRoutes(
  app: FastifyInstance
): Promise<void> {
  await app.register(fastifySwagger, {
    mode: 'static',
    specification: {
      document: openApiDocument as never
    }
  });

  await app.register(fastifySwaggerUi, {
    routePrefix: '/docs',
    staticCSP: true,
    uiConfig: {
      deepLinking: true,
      docExpansion: 'list',
      persistAuthorization: true,
      displayRequestDuration: true
    },
    theme: {
      title: 'All Of Me API Docs'
    }
  });
}
